require "test_helper"

class Fasp::Rms::V0::FeaturesTest < ActionDispatch::IntegrationTest
  setup do
    @server = fasp_base_servers(:mastodon_server)
  end

  test "unauthenticated access is prohibited" do
    get fasp_rms_v0_features_path, as: :json

    assert_response :unauthorized
  end

  test "authenticated request returns results successfully" do
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_features_url, "")

    get fasp_rms_v0_features_path, as: :json, headers: authenticated_headers

    assert_response :ok

    expected_response = {
      "contentSecurityPolicy" => {
        "hosts" => [ "http://fasp.example.com" ]
      },
      "contentTypes" => [
        "image/gif",
        "image/jpeg",
        "image/jxl",
        "image/png",
        "image/webp"
      ],
     "representations" => [
       {
         "mediaType" => "image",
         "variants" => [
           {
             "type" => "dynamic",
             "definition" => "/d/:width/:height.:ext",
             "args" => {
               "width" => "integer",
               "height" => "integer",
               "ext" => "string"
             }
           }
         ]
       }
     ]
    }
    parsed_response = JSON.parse(response.body)

    assert parsed_response.is_a?(Hash)
    assert_equal expected_response, parsed_response
  end
end
