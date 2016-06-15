require "secret_env/version"
require 'yaml'

module SecretEnv
  SECRETS_FILE = 'config/secret_env.yml'

  def self.load(env: 'development')
    config = YAML.load_file(SECRETS_FILE).fetch(env)

    storage = if config['storage']
                case config['storage'].fetch('type')
                when 'plain'
                  Storage::Plain.new(namespace: config['storage']['namespace'])
                when 'credstash'
                  Storage::CredStash.new(namespace: config['storage']['namespace'])
                else
                  raise "Unknown storage type: #{config['storage']['type']}"
                end
              else
                Storage::Plain.new
              end

    Array(config.fetch('env')).each do |key, raw_value|
      record = Record.new(key: key, raw_value: raw_value, storage: storage)
      ENV[record.key] = record.value
    end
  end

  class Record
    attr_reader :key

    def initialize(key:, raw_value:, storage: Storage::Plain.new)
      @key = key
      @raw_value = raw_value
      @storage = storage
    end

    def value
      scanner = StringScanner.new(@raw_value)
      parts = []
      while part = scanner.scan_until(/#\{(.*?)\}/)
        secret_key = scanner.matched[2..-2] # Extract "secret" from "\#{secret}"
        secret = @storage.retrieve(secret_key)
        parts << part.gsub(scanner.matched, secret)
      end
      parts.join
    end
  end

  module Storage
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

require 'secret_env/rails' if defined?(Rails)
