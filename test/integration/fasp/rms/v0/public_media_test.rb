require "test_helper"

class Fasp::Rms::V0::PublicMediaTest < ActionDispatch::IntegrationTest
  setup do
    @file_id = media_files(:avatar).id
    @file_ext = Rack::Mime::MIME_TYPES.key(media_files(:avatar).content_type)

    server = fasp_base_servers(:mastodon_server)
    private_pem = server.fasp_private_key_pem
    key = OpenSSL::PKey.read(private_pem)
    server.update!(public_key_pem: key.public_to_pem)
    digest = Digest::SHA256.base64digest("http://www.example.com/fasp/rms/mastodon-example-com/#{@file_id}#{@file_ext}")
    sign = key.sign(nil, digest)
    @sig = Base64.encode64(sign)
  end

#   test "unauthenticated access is prohibited" do
#     get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: @file_ext), params: { sig: @sig }, as: :json
#
#     assert_response :unauthorized
#   end

  test "authenticated request with accessible medium" do
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: @file_ext, sig: @sig), as: :json
    assert_response :ok

    parsed_response = JSON.parse(response.body)

    assert parsed_response.is_a?(Hash)
    assert_equal success_response, parsed_response
  end



#
#   test "authenticated request with invalid id returns a 404 status" do
#     authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_medium_url(id: "abc123"), "")
#
#     get fasp_rms_v0_medium_path(id: "abc123"), as: :json, headers: authenticated_headers
#
#     assert_response :not_found
  # end

  private

  def success_response
    {}.as_json
  end
end
