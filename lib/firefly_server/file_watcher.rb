class FireflyServer
  class FileWatcher
    attr_reader(*%w[ listener configuration ])

    def initialize(configuration)
      @configuration = configuration
      @listener = nil
    end

    def on_change(&block)
      configuration.file_change_callbacks << block if block
      self
    end

    def watch!(&file_change_callback)
      # prevent multiple listeners
      listener.stop if listener
      # always mute the Listen logger due to verbosity
      if !Listen.logger
        Listen.logger = Logger.new(STDOUT)
        Listen.logger.level = Logger::WARN
      end
      @listener = Listen.to(*configuration.watch_paths) do |modified, added, removed|
        ignored = []
        [modified, added, removed].each do |paths|
          # remove ignored paths
          paths.reject! do |path|
            configuration.ignore_paths.any? do |ignore_path|
              if ignore_path.is_a?(String)
                ignored << path if path.start_with?(ignore_path)
                true
              elsif ignore_path.is_a?(Regexp)
                ignored << path if path =~ ignore_path
                true
              else
                raise(
                  ArgumentError,
                  "unknown ignore path (expected string or regex): #{ignore_path.class} - #{ignore_path.inspect}"
                )
              end
            end
          end
        end
        # trigger change callbacks
        callbacks = (configuration.file_change_callbacks + [file_change_callback]).compact
        if !callbacks.empty?
          change_event = ChangeEvent.new(ignored: ignored, modified: modified, added: added, removed: removed)
          callbacks.each do |callback|
            callback.call(change_event)
          end
        end
      end
      listener.start
      self
    end

    class ChangeEvent
      CATEGORIES = %w[ ignored modified added removed ]
      attr_writer(*CATEGORIES)

      def initialize(params)
        params.each do |key, value|
          send("#{key}=", value)
        end
      end

      CATEGORIES.each do |accessor|
        define_method("#{accessor}?") { send(accessor).any? }
        define_method("#{accessor}") { Array(instance_variable_get("@#{accessor}")) }
      end

      def to_h
        CATEGORIES.map { |category| [category.to_sym, send(category)] }.to_h
      end
    end
  end
end
