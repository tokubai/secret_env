require 'secret_env/version'
require 'secret_env/storage'
require 'yaml'

module SecretEnv
  SECRETS_FILE = 'config/secret_env.yml'

  def self.load(env: 'development')
    config = YAML.load_file(SECRETS_FILE).fetch(env)

    storage = Storage.setup(config['storage'])

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
      parts << scanner.rest
      parts.join
    end
  end
end

require 'secret_env/rails' if defined?(Rails)
