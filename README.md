# SecretEnv
SecretEnv is a environment variables manager for rails. SecretEnv can resolve secret variables from storages.

```yaml
development:
  env:
    AUTH_SECRET: secret
    DATABASE_URL: 'mysql2://local_user@localhost:3306'

staging:
  storage:
    type: credstash
    namespace: awesome_app.staging.
  env:
    AUTH_SECRET: '#{auth_secret}'
    DATABASE_URL: 'mysql2://db_user:#{db_password}@db-staging:3306/main?read_timeout=10&encoding=utf8'

production:
  storage:
    type: credstash
    namespace: awesome_app.production.
  env:
    AUTH_SECRET: '#{auth_secret}'
    DATABASE_URL: 'mysql2://db_user:#{db_password}@db-production:3306/main?read_timeout=10&encoding=utf8'
```

## Features
- Put secrets out of a config file in repository. You can choose backend storages.
- Configure multi environments via one file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'secret_env'
```

And then execute:

    $ bundle

Put config/secret_env.yml in your application.

## Storages
SecretEnv resolves keys in given namespace. If you set `some.namespace`, SecretEnv finds `some.namespace.super_secret` key from storages.

### type: plain
This is default storage type. This type does not retrieve secrets, just extract it as full namespaced key.

### type: credstash
This type finds secrets via credstash. You have to bundle 'rcredstash'.

```ruby
gem 'secret_env'
gem 'rcredstash'
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adorechic/secret_env.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
