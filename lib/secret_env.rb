require "secret_env/version"

module SecretEnv
  def self.load
    ENV['PASSWORD'] = 'awesome_pass'
  end
end
