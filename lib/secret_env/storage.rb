module SecretEnv
  module Storage
    class << self
      def setup(config)
        if config
          klass(config.fetch('type')).new(namespace: config['namespace'])
        else
          Storage::Plain.new
        end
      end

      private

      def klass(type)
        case type
        when 'plain'
          Storage::Plain
        when 'credstash'
          Storage::CredStash
        else
          raise "Unknown storage type: #{type}"
        end
      end
    end

    class Base
      attr_reader :namespace

      def initialize(namespace: '')
        @namespace = namespace
      end

      def retrieve(secret_key)
        raise NotImplemedError
      end

      private

      def full_key(secret_key)
        "#{namespace}#{secret_key}"
      end
    end

    class Plain < Base
      def retrieve(secret_key)
        "#\{#{full_key(secret_key)}\}"
      end
    end

    class CredStash < Base
      def retrieve(secret_key)
        ::CredStash.get(full_key(secret_key))
      end
    end
  end
end
