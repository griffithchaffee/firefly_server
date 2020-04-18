require "test_helper"

class FireflyServer::FileWatcher::Test < Minitest::Test
  def test_watch!
    test_tmp_path = File.expand_path("../../tmp", __FILE__)
    configuration = FireflyServer::Configuration.new
    file_watcher = FireflyServer::FileWatcher.new(configuration)
    change_variable = :@test_changes
    set_change = -> (value) do
      configuration.instance_variable_set(change_variable, value)
    end
    reset_before_change = -> do
      set_change.call(:reset)
    end
    wait_for_change = -> do
      # wait for event to be processed
      10.times do |attempt|
        break if configuration.instance_variable_get(change_variable) != :reset
        sleep(0.05)
      end
    end
    assert_change = -> (expected_change_h) do
      assert_equal(
        expected_change_h,
        configuration.instance_variable_get(change_variable)
      )
    end
    # ensure dne_dir does not exist
    dne_dir = "#{test_tmp_path}/dne"
    if Dir.exist?(dne_dir)
      Dir.delete(dne_dir)
    end
    # no directory
    configuration.watch_paths = dne_dir
    assert_raises(Errno::ENOENT) do
      file_watcher.watch!
    end
    # create directory
    test_dir = "#{test_tmp_path}/test_watch"
    if !Dir.exist?(test_dir)
      Dir.mkdir(test_dir)
    end
    # delete file
    test_file = "#{test_dir}/file.txt"
    if File.exist?(test_file)
      File.delete(test_file)
    end
    # watch directory
    configuration.watch_paths = test_dir
    reset_before_change.call
    file_watcher.watch! do |change|
      set_change.call(change.to_h)
    end
    assert_equal(:processing_events, file_watcher.listener.state)
    assert_equal(true, file_watcher.listener.processing?)
    # create file
    File.open(test_file, "w") { |f| f.write("word1") }
    wait_for_change.call
    assert_change.call(ignored: [], modified: [], added: [test_file], removed: [])
    # update file
    reset_before_change.call
    File.open(test_file, "a") { |f| f.write(" word2") }
    wait_for_change.call
    assert_change.call(ignored: [], modified: [test_file], added: [], removed: [])
    # ignore file
    configuration.ignore_paths = test_file
    reset_before_change.call
    File.open(test_file, "a") { |f| f.write(" word3") }
    wait_for_change.call
    assert_change.call(ignored: [test_file], modified: [], added: [], removed: [])
    # remove file
    configuration.ignore_paths = nil
    reset_before_change.call
    File.delete(test_file)
    wait_for_change.call
    assert_change.call(ignored: [], modified: [], added: [], removed: [test_file])
  end
end
