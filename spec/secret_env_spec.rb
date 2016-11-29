require 'spec_helper'
require 'rcredstash'

describe SecretEnv do
  describe '.load' do
    before do
      expect(YAML).to receive(:load_file).with('config/secret_env.yml').and_return(yml)
    end

    let(:yml) do
      {
        'development' => {
          'env' => {
            'PASSWORD' => '#{awesome_pass}',
            'PORT' => 80
          }
        }
      }
    end

    after do
      ENV['PASSWORD'] = nil
      ENV['PORT'] = nil
    end

    it 'parses and set to ENV' do
      expect {
        SecretEnv.load
      }.to change {
        ENV['PASSWORD']
      }.from(nil).to('#{awesome_pass}')

      expect(ENV['PORT']).to eq '80'
    end

    context 'without envs' do
      let(:yml) do
        {
          'development' => {
            'env' => nil
          }
        }
      end

      it 'does not raise error' do
        expect { SecretEnv.load }.to_not raise_error
      end
    end

    context 'with credstash' do
      let(:yml) do
        {
          'development' => {
            'storage' => { 'type' => 'credstash' },
            'env' => {
              'PASSWORD' => '#{awesome_pass}'
            }
          }
        }
      end

      it 'retrieve from credstash' do
        expect(::CredStash).to receive(:get).with('awesome_pass').and_return('credstash')
        expect {
          SecretEnv.load
        }.to change {
          ENV['PASSWORD']
        }.from(nil).to('credstash')
      end

      context 'if secret is not found' do
        it 'raises error' do
          expect(::CredStash).to receive(:get).with('awesome_pass').and_return(nil)
          expect {
            SecretEnv.load
          }.to raise_error(SecretEnv::KeyNotFound, 'awesome_pass')
        end
      end

      context 'with namespace' do
        let(:yml) do
          {
            'development' => {
              'storage' => {
                'type' => 'credstash',
                'namespace' => 'myapp.development.'
              },
              'env' => {
                'PASSWORD' => '#{awesome_pass}'
              }
            }
          }
        end

        it 'retrieve from credstash with prefix' do
          expect(::CredStash).to receive(:get).with('myapp.development.awesome_pass').and_return('credstash')
          expect {
            SecretEnv.load
          }.to change {
            ENV['PASSWORD']
          }.from(nil).to('credstash')
        end
      end

      describe 'key reference' do
        let(:yml) do
          {
            'development' => {
              'storage' => {
                'type' => 'credstash',
                'namespace' => 'myapp.development.'
              },
              'env' => {
                'DATABASE_URL' => 'mysql2://db_user:#{db_password}@#{db_host}:3306',
                'db_host' => 'db_slave'
              }
            }
          }
        end

        before do
          allow(::CredStash).to receive(:get).and_return(nil)
          allow(::CredStash).to receive(:get).with('myapp.development.db_password').and_return('secret_password')
        end

        after do
          ENV['db_host'] = nil
          ENV['DATABASE_URL'] = nil
        end

        it 'retrieve from credstash with prefix' do
          expect {
            SecretEnv.load
          }.to change {
            ENV['DATABASE_URL']
          }.from(nil).to('mysql2://db_user:secret_password@db_slave:3306')
        end

        context 'with env' do
          before do
            ENV['db_host'] = 'backup_db'
          end

          after do
            ENV['db_host'] = nil
          end

          it 'overwrites secret with env value' do
            SecretEnv.load
            expect(ENV['db_host']).to eq('backup_db')
            expect(ENV['DATABASE_URL']).to eq('mysql2://db_user:secret_password@backup_db:3306')
          end
        end
      end

      describe 'multiple keys' do
        context 'when retrieve first key' do
          let(:yml) do
            {
              'development' => {
                'storage' => {
                  'type' => 'credstash',
                  'namespace' => 'myapp.development.'
                },
                'env' => {
                  'DB_USER' => 'db_user',
                  'DB_USER2' => 'db_user2',
                  'DATABASE_URL' => 'mysql2://#{DB_USER || DB_USER2}:#{db_password || db_password2}@#{db_host || db_host2}:3306',
                  'db_host' => 'db_slave',
                  'db_host2' => 'db_slave2'
                }
              }
            }
          end

          before do
            allow(::CredStash).to receive(:get).and_return(nil)
            allow(::CredStash).to receive(:get).with('myapp.development.db_password').and_return('secret_password')
            allow(::CredStash).to receive(:get).with('myapp.development.db_password2').and_return('secret_password2')
          end

          it 'retrieve by second key' do
            expect {
              SecretEnv.load
            }.to change {
              ENV['DATABASE_URL']
            }.from(nil).to('mysql2://db_user:secret_password@db_slave:3306')
          end
        end

        context 'when retrieve second key' do
          let(:yml) do
            {
              'development' => {
                'storage' => {
                  'type' => 'credstash',
                  'namespace' => 'myapp.development.'
                },
                'env' => {
                  'DB_USER2' => 'db_user2',
                  'DATABASE_URL' => 'mysql2://#{DB_USER || DB_USER2}:#{db_password || db_password2}@#{db_host || db_host2}:3306',
                  'db_host2' => 'db_slave2'
                }
              }
            }
          end

          before do
            allow(::CredStash).to receive(:get).and_return(nil)
            allow(::CredStash).to receive(:get).with('myapp.development.db_password2').and_return('secret_password2')
          end

          it 'retrieve by first key' do
            expect {
              SecretEnv.load
            }.to change {
              ENV['DATABASE_URL']
            }.from(nil).to('mysql2://db_user2:secret_password2@db_slave2:3306')
          end
        end

        after do
          ENV['DB_USER'] = nil
          ENV['DB_USER2'] = nil
          ENV['db_host'] = nil
          ENV['db_host2'] = nil
          ENV['DATABASE_URL'] = nil
        end
      end
    end
  end

  describe SecretEnv::Record do
    it 'extracts secrets and combines them' do
      [
        'none',
        '#{s}',
        'pre#{s}',
        '#{s}suf',
        'pre#{s}suf',
        'pre#{s1}mid#{s2}suf',
      ].each do |raw_value|
        record = SecretEnv::Record.new(key: 'key', raw_value: raw_value)
        expect(record.value).to eq raw_value
      end
    end
  end
end
