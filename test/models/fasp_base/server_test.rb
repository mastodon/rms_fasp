require "test_helper"

class FaspBase::ServerTest < ActiveSupport::TestCase
  test "newly created servers derive a namespace from `base_url`" do
    server = FaspBase::Server.create!(base_url: "https://fedi.example.com", user: fasp_base_users(:fedi_admin))

    assert_equal "fedi-example-com", server.namespace

    server = FaspBase::Server.create!(base_url: "https://fedi.localhost:3000", user: fasp_base_users(:fedi_admin))

    assert_equal "fedi-localhost-3000", server.namespace
  end
end
