require "test_helper"

class FireflyServerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil(FireflyServer::VERSION)
  end

  def test_configure
    server = FireflyServer.new
    server.configure do |config|
      assert_equal(server.configuration, config)
    end
  end
end
