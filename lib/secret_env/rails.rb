module SecretEnv
  class Railtie < ::Rails::Railtie
    config.before_configuration { SecretEnv.load }
  end
end
