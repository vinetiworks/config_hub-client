require 'spec_helper'
require 'config_hub/client'

RSpec.describe ConfigHub::Client do
  let(:base_url) { 'https://config.example.com' }
  let(:token) { 'abcdefg-glahfkwehjf823498' }
  let(:context) { 'test;customer;instance' }
  let(:options) { {} }

  describe 'an instance' do
    subject { described_class.new(base_url, token, context, options) }

    before do
      stub_request(:get, "#{base_url}/rest/pull").to_return(body: response.to_json)
    end

    describe 'properties' do
      let(:response) do
        {
          'generatedOn' => '08/29/2017 00:20:23',
          'account' => 'MyAcct',
          'repo' => 'MyApp',
          'context' => 'test;tenant;dev-1',
          'files' => {},
          'properties' => {
            'salesforce.web_host' => {
              'val' => 'http://scheduling.example.com'
            },
            'thiskeyisnil' => {},
            'aboolean' => {
              'val' => 'false',
              'type' => 'Boolean'
            },
            'afloat' => {
              'val' => '2',
              'type' => 'Float'
            },
            'along' => {
              'val' => '2',
              'type' => 'Long'
            },
            'ainteger' => {
              'val' => '2',
              'type' => 'Integer'
            },
            'adouble' => {
              'val' => '2',
              'type' => 'Double'
            },
            'ajson' => {
              'val' => "{\"key\": \"value\"}",
              'type' => "JSON"
            }
          }
        }
      end

      describe '#pull' do
        it 'should pull config' do
          expect(subject.pull).to eq response
        end
      end

      describe '#fetch' do
        it 'should raise an error if config was not pulled' do
          expect { subject.fetch('salesforce.web_host') }.to raise_error(ConfigHub::ConfigNotPulledError)
        end

        describe 'when config has been pulled' do
          before do
            subject.pull
          end

          it 'should fetch pulled config' do
            expect(subject.fetch('salesforce.web_host')).to eq 'http://scheduling.example.com'
          end

          it 'should take a block for default value' do
            expect(subject.fetch('nonexistent.key') { 'foo' }).to eq('foo')
          end

          it 'should not use default value if key is intentionally nil' do
            expect(subject.fetch('thiskeyisnil') { 'foo' }).to eq(nil)
          end

          it 'should cast Boolean values' do
            expect(subject.fetch('aboolean')).to eq(false)
          end

          it 'should cast Integer values' do
            expect(subject.fetch('ainteger')).to eq(2)
          end

          it 'should cast Float values' do
            expect(subject.fetch('afloat')).to eq(2.0)
          end

          it 'should cast Long values' do
            expect(subject.fetch('along')).to eq(2)
          end

          it 'should cast Double values' do
            expect(subject.fetch('adouble')).to eq(2.0)
          end

          it 'should cast JSON values' do
            expect(subject.fetch('ajson')).to eq({'key' => 'value'})
          end
        end
      end

      describe '#to_h' do
        it 'should raise an error if config was not pulled' do
          expect { subject.to_h }.to raise_error(ConfigHub::ConfigNotPulledError)
        end

        describe 'when config has been pulled' do
          before do
            subject.pull
          end

          it 'returns a hash of the keys to values from the properties' do
            expect(subject.to_h).to be_a(Hash)
            expect(subject.to_h.keys).to include('salesforce.web_host', 'thiskeyisnil')
            expect(subject.to_h['salesforce.web_host']).to eq 'http://scheduling.example.com'
          end
        end
      end

      describe 'request headers' do
        let(:options) do
          { headers: { some_other_header: 'a value' } }
        end

        it 'should add options as headers' do
          headers = subject.send(:headers)
          expect(headers).to eq(
            'Client-Token' => token,
            'Context' => context,
            'Some-Other-Header' => 'a value'
          )
        end
      end

      describe 'a failed request' do
        let(:headers) do
          {
            'etag' => 'Invalid API token.'
          }
        end

        before do
          # conn = subject.instance_variable_get(:@conn)
          # stub_faraday_request(conn) do |stub|
          #   stub.get('/rest/pull') { [406, headers, ''] }
          # end
          stub_request(:get, "#{base_url}/rest/pull").to_return(status: 406)
        end

        it 'should raise an error' do
          expect { subject.pull }.to raise_error(ConfigHub::RequestError)
        end
      end
    end

    describe 'files' do
      describe 'files included in pull' do
        let(:response) do
          {
            'generatedOn' => '08/29/2017 00:20:23',
            'account' => 'MyAcct',
            'repo' => 'MyApp',
            'context' => 'test;tenant;dev-1',
            'files' => {
              'example.file' => {
                'content' => "{\n    \"thisisjson\": \"hello\",\n    \"nested\": {\n        \"objects\": \"areok\"\n    }\n}",
                'content-type' => 'text/plain'
              }
            },
            'properties' => {}
          }
        end

        describe 'when config has been pulled' do
          before do
            subject.pull
          end

          it 'should fetch files' do
            file = subject.fetch_file('example.file')
            expect(JSON.parse(file)).to eq({'thisisjson' => 'hello', 'nested' => {'objects' => 'areok'}})
          end
        end
      end

      describe 'files not included in pull' do
        let(:options) do
          {'No-Files' => true}
        end

        let(:response) do
          {
            'generatedOn' => '08/29/2017 00:20:23',
            'account' => 'MyAcct',
            'repo' => 'MyApp',
            'context' => 'test;tenant;dev-1',
            'properties' => {}
          }
        end

        let(:file_response) { "{\n    \"thisisjson\": \"hello\",\n    \"nested\": {\n        \"objects\": \"areok\"\n    }\n}" }

        before do
          stub_request(:get, "#{base_url}/rest/rawFile")
            .with(headers: {'File' => 'example.file'})
            .to_return(body: file_response)
        end

        it 'should fetch file from server' do
          expect(subject.fetch_file('example.file')).to eq file_response
          expect(a_request(:get, "#{base_url}/rest/rawFile")).to have_been_made
        end


      end
    end
  end
end
