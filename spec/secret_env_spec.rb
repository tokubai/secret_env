require 'spec_helper'

describe SecretEnv do
  describe '.load' do
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
