require "test_helper"

class Fasp::Rms::V0::NamespacesTest < ActionDispatch::IntegrationTest
  setup do
    @server = FaspBase::Server.create!(user: fasp_base_users(:fedi_admin), base_url: "https://fedi.example.com/fasp")
  end

  test "unauthenticated access is prohibited" do
    get fasp_rms_v0_namespace_path, as: :json

    assert_response :unauthorized
  end

  test "authenticated request returns results successfully" do
    authenticated_headers = request_authentication_headers(@server, :get, fasp_rms_v0_namespace_url, "")

    get fasp_rms_v0_namespace_path, as: :json, headers: authenticated_headers

    assert_response :ok

    parsed_response = JSON.parse(response.body)
    expected_response = { "namespace" => "fedi-example-com" }

    assert_equal expected_response, parsed_response
  end
end
