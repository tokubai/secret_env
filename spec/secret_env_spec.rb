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
