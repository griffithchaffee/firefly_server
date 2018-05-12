require "test_helper"

class FireflyServer::Configuration::Test < Minitest::Test
  def test_default_values
    configuration = FireflyServer::Configuration.new
    assert_equal(3, configuration.restart_attempt_throttle_threshold)
    assert_equal(3, configuration.restart_attempt_throttle_sleep)
    assert_equal(["SIGINT"], configuration.exit_signals)
  end

  def test_validate!
    configuration = FireflyServer::Configuration.new
    # configuration should initially be invalid
    assert_raises(ArgumentError) do
      configuration.validate!
    end
    # required options
    %w[ pid_file start_server stop_server watch_paths ].each do |required_option|
      configuration.send("#{required_option}=", "test")
    end.each do |required_option|
      # should be initially valid
      assert_equal(configuration, configuration.validate!, configuration.inspect)
      # assert option validated
      configuration.send("#{required_option}=", nil)
      assert_raises(ArgumentError, "#{required_option} is validated") do
        configuration.validate!
      end
      # reset for next option
      configuration.send("#{required_option}=", "test")
    end
  end

  def test_array_attributes
    configuration = FireflyServer::Configuration.new
    %w[
      exit_signals
      watch_paths
      ignore_paths
    ].each do |attribute|
      assert_equal(Array, configuration.send(attribute).class, "#{attribute} default should be an Array")
      configuration.send("#{attribute}=", "test")
      assert_equal(["test"], configuration.send(attribute), "#{attribute}='test'")
      configuration.send("#{attribute}=", ["test"])
      assert_equal(["test"], configuration.send(attribute), "#{attribute}=['test']")
      configuration.send("#{attribute}") << "new"
      assert_equal(["test", "new"], configuration.send(attribute), "#{attribute} << 'new'")
    end

  end
end
