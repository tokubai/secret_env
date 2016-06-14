require 'spec_helper'

describe SecretEnv do
  describe '.load' do
    before do
      expect(YAML).to receive(:load_file).with('config/secret_env.yml').and_return(yml)
    end

    let(:yml) do
      {
        'env' => {
          'PASSWORD' => 'awesome_pass'
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
      }.from(nil).to('awesome_pass')
    end
  end
end
