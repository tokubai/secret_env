require "secret_env/version"
require 'yaml'

module SecretEnv
  SECRETS_FILE = 'config/secret_env.yml'

  def self.load
    env = YAML.load_file(SECRETS_FILE).fetch('env')
    env.each do |key, value|
      record = Record.new(key: key, value: value)
      ENV[record.key] = record.value
    end
  end

  class Record
    attr_reader :key, :value

    def initialize(key:, value:)
      @key = key
      @value = value
    end
  end
end
