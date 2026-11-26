require "test_helper"

class Fasp::Rms::V0::PublicMediaTest < ActionDispatch::IntegrationTest
  setup do
    @file_id = media_files(:avatar).id
    @file_ext = Rack::Mime::MIME_TYPES.key(media_files(:avatar).content_type)
    @sig = create_signature
  end

  test "unauthenticated access is prohibited" do
    invalid_sig = @sig + "9g==\n"
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png"), params: { sig: invalid_sig }, as: :json

    assert_response :unauthorized
  end

  test "authenticated request with accessible medium" do
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png", any: "/s/300/400", sig: @sig), as: :json

    assert_redirected_to img_proxy_path
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

  def img_proxy_path
    "http://localhost:8080/Za2DlNng4_F9P1_w0UsKzDq-HiY9QHJJiMKytZUTcv0/:s:300:400/czM6Ly9maWxlcy5leGFtcGxlLmNvbS8zNzY5MjY3Njc.png"
  end

  def create_signature
    server = fasp_base_servers(:mastodon_server)
    private_pem = server.fasp_private_key_pem
    key = OpenSSL::PKey.read(private_pem)

    server.update!(public_key_pem: key.public_to_pem)
    digest = Digest::SHA256.base64digest("http://www.example.com/fasp/rms/mastodon-example-com/#{@file_id}/s/300/400#{@file_ext}")
    sign = key.sign(nil, digest)
    Base64.encode64(sign)
  end
end
