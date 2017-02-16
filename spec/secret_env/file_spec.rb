require 'spec_helper'

describe SecretEnv do
  describe '.load via file' do
    before do
      expect(YAML).to receive(:load_file).with('config/secret_env.yml').and_return(yml)
      expect(::File).to receive(:readlines).with('config/secret_env.local').and_return(lines)
    end

    let(:yml) do
      {
        'development' => {
          'storage' => { 'type' => 'file' },
          'env' => {
            'PASSWORD' => '#{awesome_pass}'
          }
        }
      }
    end

    let(:lines) do
      ["awesome_pass=file\n"]
    end

    after do
      ENV['PASSWORD'] = nil
    end

    it 'retrieves from local file' do
      expect {
        SecretEnv.load
      }.to change {
        ENV['PASSWORD']
      }.from(nil).to('file')
    end

    context 'with namespace' do
      let(:yml) do
        {
          'development' => {
            'storage' => { 'type' => 'file', 'namespace' => 'myapp.development.' },
            'env' => {
              'PASSWORD' => '#{awesome_pass}'
            }
          }
        }
      end

      let(:lines) do
        ["myapp.development.awesome_pass=file\n"]
      end

      it 'retrieves from local file' do
        expect {
          SecretEnv.load
        }.to change {
          ENV['PASSWORD']
        }.from(nil).to('file')
      end
    end
  end
end
