module SecretEnv
  class Railtie < ::Rails::Railtie
    config.before_configuration { SecretEnv.load(env: Rails.env) }
  end
end
