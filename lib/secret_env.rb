require "secret_env/version"
require 'yaml'

module SecretEnv
  SECRETS_FILE = 'config/secret_env.yml'

  def self.load
    env = YAML.load_file(SECRETS_FILE).fetch('env')
    env.each do |key, value|
      ENV[key] = value
    end
  end
end
