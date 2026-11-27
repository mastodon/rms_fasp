require "test_helper"

class Fasp::Rms::V0::PublicMediaTest < ActionDispatch::IntegrationTest
  setup do
    @sig = create_signature
  end

  test "with invalid signature access is prohibited" do
    @file_id = media_files(:avatar).id
    sig = create_signature
    invalid_sig = sig + "9g==\n"

    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png"), params: { sig: invalid_sig }, as: :json

    assert_response :unauthorized
  end

  test "valid request with accessible medium" do
    @file_id = media_files(:avatar).id
    @any = "/s/300/400"
    sig = create_signature
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png", any: @any, sig: sig), as: :json

    assert_redirected_to  "http://localhost:8080/1bv62wFpUHwniGN0aqZIb64HkMGLqvb8swrOV3BEL9g/s:300:400/czM6Ly9maWxlcy5leGFtcGxlLmNvbS8zNzY5MjY3Njc.png"
  end

  test "valid request without :any path segment" do
    @file_id = media_files(:avatar).id
    @any = nil
    sig = create_signature
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png", sig: sig), as: :json

    assert_redirected_to "http://localhost:8080/82aMiGz9Sx_S3WIhC9cbZA-j9JKOODCM54ClcahHdTk/czM6Ly9maWxlcy5leGFtcGxlLmNvbS8zNzY5MjY3Njc.png"
  end

  test "valid signature request with invalid id returns a 404 status" do
    @file_id = 12345567
    @any = "/s/300/400"
    sig = create_signature
    get fasp_rms_path(id: @file_id, namespace: "mastodon-example-com", ext: "png", any: @any, sig: sig), as: :json

    assert_response :not_found
  end

  private

  def create_signature
    file_ext = Rack::Mime::MIME_TYPES.key(media_files(:avatar).content_type)
    server = fasp_base_servers(:mastodon_server)
    private_pem = server.fasp_private_key_pem
    key = OpenSSL::PKey.read(private_pem)

    server.update!(public_key_pem: key.public_to_pem)
    digest = Digest::SHA256.base64digest("http://www.example.com/fasp/rms/mastodon-example-com/#{@file_id}#{@any}#{file_ext}")
    sign = key.sign(nil, digest)
    Base64.encode64(sign)
  end
end
