require "test_helper"

class Fasp::Rms::V0::MediaTest < ActionDispatch::IntegrationTest
  setup do
    @server = fasp_base_servers(:mastodon_server)
  end

  test "unauthenticated access is prohibited" do
    storage_success = storage_requests(:successful_stored)
    get fasp_rms_v0_medium_path(storage_success.id), as: :json

    assert_response :unauthorized
  end

  test "authenticated request with accessible medium" do
    storage_success = storage_requests(:successful_stored)
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url(storage_success.id), "")

    get fasp_rms_v0_medium_path(storage_success.id), as: :json, headers: authenticated_headers
    assert_response :ok

    parsed_response = JSON.parse(response.body)

    assert parsed_response.is_a?(Hash)
    assert_equal success_response, parsed_response
  end

  test "authenticated request with rejected medium" do
    storage_reject = storage_requests(:one)
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url(storage_reject.id), "")


    get fasp_rms_v0_medium_path(storage_reject.id), as: :json, headers: authenticated_headers
    assert_response :ok

    parsed_response = JSON.parse(response.body)
    assert_equal reject_response, parsed_response
  end

  test "authenticated request with processing medium" do
    storage_processing = storage_requests(:processing)
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url(storage_processing.id), "")

    get fasp_rms_v0_medium_path(storage_processing.id), as: :json, headers: authenticated_headers
    assert_response :ok

    parsed_response = JSON.parse(response.body)
    assert_equal pending_response(:processing), parsed_response
  end

  test "authenticated request with enqueued medium" do
    storage_enqueued = storage_requests(:enqueued)
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url(storage_enqueued.id), "")

    get fasp_rms_v0_medium_path(storage_enqueued.id), as: :json, headers: authenticated_headers
    assert_response :ok

    parsed_response = JSON.parse(response.body)
    assert_equal pending_response(:enqueued), parsed_response
  end

  test "authenticated request with invalid id returns a 404 status" do
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url("abc123"), "")

    get fasp_rms_v0_medium_path("abc123"), as: :json, headers: authenticated_headers

    assert_response :not_found
  end

  private

  def reject_response
    {
     id: storage_requests(:one).id,
     activityPub: {
       id: storage_requests(:one).ap_object.uri
     },
     originalURL: storage_requests(:one).file_url,
     status: "rejected",
     reason: {
       code: storage_requests(:one).rejection_reason,
       message: "The ActivityPub object is not public"
     }
    }.as_json
  end

  def success_response
    {
     id: storage_requests(:successful_stored).id,
     activityPub: {
       id: storage_requests(:successful_stored).ap_object.uri
     },
     originalURL: storage_requests(:successful_stored).file_url,
     status: "ok",
     contentType: media_files(:photo).content_type,
     contentLength: media_files(:photo).file_size,
     contentDigest: media_files(:photo).sha512,
     metadata: {
       height: media_files(:photo).height,
       width: media_files(:photo).width
     },
     extension: ".jpeg",
     representations: []
    }.as_json
  end

  def pending_response(state)
    {
     id: storage_requests(state).id,
     activityPub: {
       id: storage_requests(state).ap_object.uri
     },
     originalURL: storage_requests(state).file_url,
     status: state.to_s
    }.as_json
  end
end
