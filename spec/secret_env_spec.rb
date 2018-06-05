require 'spec_helper'

describe SecretEnv do
  describe '.load via plain' do
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
  end

  describe '.env?' do
    before do
      expect(YAML).to receive(:load_file).with('config/secret_env.yml').and_return(yml)
    end

    let(:yml) do
      {
        'development' => {}
      }
    end

    it 'exists' do
      expect(SecretEnv.env?).to be_truthy
    end

    context 'without envs' do
      it 'dose not exit' do
        expect(SecretEnv.env?(env: 'production')).to be_falsey
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
