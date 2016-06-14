require 'spec_helper'
require 'rcredstash'

describe SecretEnv do
  describe '.load' do
    before do
      expect(YAML).to receive(:load_file).with('config/secret_env.yml').and_return(yml)
    end

    let(:yml) do
      {
        'env' => {
          'PASSWORD' => '#{awesome_pass}'
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

    context 'with credstash' do
      let(:yml) do
        {
          'storage' => { 'type' => 'credstash' },
          'env' => {
            'PASSWORD' => '#{awesome_pass}'
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
    end
  end
end
