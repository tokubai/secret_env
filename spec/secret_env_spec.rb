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
            'PASSWORD' => '#{awesome_pass}'
          }
        }
      }
    end

    after do
      ENV['PASSWORD'] = nil
    end

    it 'parses and set to ENV' do
      expect {
        SecretEnv.load
      }.to change {
        ENV['PASSWORD']
      }.from(nil).to('#{awesome_pass}')
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
          }.to raise_error(SecretEnv::KeyNotFound)
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
