require "test_helper"

class Fasp::Rms::V0::BatchesTest < ActionDispatch::IntegrationTest
  setup do
    @server = fasp_base_servers(:mastodon_server)
  end

  test "unauthenticated access is prohibited" do
    post fasp_rms_v0_batch_path, params: valid_params, as: :json

    assert_response :unauthorized
  end

  test "authenticated request with valid params creates records, enqueues job and returns per media IDs successfully" do
    authenticated_headers = request_authentication_headers(@server, :post, fasp_rms_v0_batch_url, valid_params)

    assert_difference -> { ApObject.count }, 1 do
      assert_difference -> { StorageRequest.count }, 2 do
        assert_enqueued_jobs 1, only: ProcessApObjectJob do
          post fasp_rms_v0_batch_path, as: :json, params: valid_params, headers: authenticated_headers
        end
      end
    end

    assert_response :accepted

    parsed_response = JSON.parse(response.body)

    assert parsed_response.is_a?(Hash)
    media_array = parsed_response["media"]
    assert_equal 2, media_array.size

    media_array.each do |entry|
      assert StorageRequest.where(id: entry["id"]).exists?
    end
  end

  test "authenticated request with valid params does not create a new ApObject if one already exists" do
    ApObject.create!(uri: valid_params[:activityPub][:id])

    authenticated_headers = request_authentication_headers(@server, :post, fasp_rms_v0_batch_url, valid_params)

    assert_no_difference -> { ApObject.count } do
      assert_enqueued_jobs 1, only: ProcessApObjectJob do
        post fasp_rms_v0_batch_path, as: :json, params: valid_params, headers: authenticated_headers
      end
    end

    assert_response :accepted
  end

  test "authenticated request with invalid data returns a 422 status" do
    invalid_params = { activityPub: { uri: "https://wrong.key.name" } }

    authenticated_headers = request_authentication_headers(@server, :post, fasp_rms_v0_batch_url, invalid_params)

    assert_no_enqueued_jobs do
      post fasp_rms_v0_batch_path, as: :json, params: invalid_params, headers: authenticated_headers
    end

    assert_response :unprocessable_content
  end

  private

  def valid_params
    {
      activityPub: {
        id: "https://example.org/~alice/note/233"
      },
      urls: [
        "https://example.com/note/233/attachment-1.png",
        "https://example.com/note/233/attachment-2.png"
      ]
    }
  end
end
