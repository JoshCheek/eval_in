# encoding: utf-8

require 'eval_in'
require 'webmock'
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.filter_run_excluding integration: true

  config.include Module.new {
    def assert_result(result, attributes)
      attributes.each do |key, value|
        expect(result.public_send key).to eq value
      end
    end
  }

  config.after do
    WebMock.reset!
  end
end

RSpec.describe EvalIn, integration: true do
  around do |spec|
    WebMock.allow_net_connect!
    spec.call
    WebMock.disable_net_connect!
  end

  it 'evaluates Ruby code through eval.in' do
    result = EvalIn.call 'print "hello, #{gets}"', stdin: "world", language: "ruby/mri-2.1", context: 'eval_in integration test'
    expect(result.exitstatus       ).to eq 0
    expect(result.language         ).to eq "ruby/mri-2.1"
    expect(result.language_friendly).to eq "Ruby — MRI 2.1"
    expect(result.code             ).to eq 'print "hello, #{gets}"'
    expect(result.output           ).to eq "hello, world"
    expect(result.status           ).to match /OK \([\d.]+ sec real, [\d.]+ sec wall, \d MB, \d+ syscalls\)/
    expect(result.url              ).to match %r(https://eval.in/\d+.json)
  end

  it 'fetches previous results from eval.in' do
    result = EvalIn.fetch_result "https://eval.in/147.json"
    expect(result.exitstatus       ).to eq 0
    expect(result.language         ).to eq "ruby/mri-1.9.3"
    expect(result.language_friendly).to eq "Ruby — MRI 1.9.3"
    expect(result.code             ).to eq %'class Greeter\r\n  def initialize(name)\r\n    @name = name\r\n  end\r\n\r\n  def greet\r\n    puts \"Hello \#{@name}!\"\r\n  end\r\nend\r\n\r\ngreeter = Greeter.new \"Charlie\"\r\ngreeter.greet'
    expect(result.output           ).to eq "Hello Charlie!\n"
    expect(result.status           ).to match /OK \([\d.]+ sec real, [\d.]+ sec wall, \d MB, \d+ syscalls\)/
    expect(result.url              ).to match %r(https://eval.in/147.json)
  end
end

RSpec.describe EvalIn::Result do
  it 'initializes with the provided attributes' do
    result = EvalIn::Result.new exitstatus:        123,
                                language:          'the language',
                                language_friendly: 'the friendly language',
                                code:              'the code',
                                output:            'the output',
                                status:            'the status'
    assert_result result,
                  exitstatus:        123,
                  language:          'the language',
                  language_friendly: 'the friendly language',
                  code:              'the code',
                  output:            'the output',
                  status:            'the status'
  end

  it 'uses sensible type-correct defaults for missing attributes' do
    assert_result EvalIn::Result.new,
                  exitstatus:        -1,
                  language:          '',
                  language_friendly: '',
                  code:              '',
                  output:            '',
                  status:            '',
                  url:               ''
    assert_result EvalIn::Result.new(language:          nil,
                                     language_friendly: nil,
                                     code:              nil,
                                     output:            nil,
                                     status:            nil,
                                     url:               nil),
                  exitstatus:        -1,
                  language:          '',
                  language_friendly: '',
                  code:              '',
                  output:            '',
                  status:            '',
                  url:               ''
  end

  it 'doesn\'t mutate the input attributes' do
    attributes = {status: 'OK'}
    EvalIn::Result.new attributes
    expect(attributes).to eq status: 'OK'
  end

  it 'logs extra attributes to the error stream' do
    expect { EvalIn::Result.new a: 1, b: 2 }.to \
      output("Unexpected attributes! [:a, :b]\n").to_stderr
  end
end


RSpec.describe 'post_code' do
  include WebMock::API

  # ACTUAL RESPONSE:
  #
  # HTTP/1.1 302 Found\r
  # Server: nginx/1.4.6 (Ubuntu)\r
  # Date: Sun, 24 Aug 2014 05:57:17 GMT\r
  # Content-Type: text/html;charset=utf-8\r
  # Content-Length: 0\r
  # Connection: keep-alive\r
  # Location: https://eval.in/182584
  # X-XSS-Protection: 1; mode=block\r
  # X-Content-Type-Options: nosniff\r
  # X-Frame-Options: SAMEORIGIN\r
  # X-Runtime: 0.042154\r
  # Strict-Transport-Security: max-age=31536000\r
  # \r
  def stub_eval_in(data=expected_data)
    stub_request(:post, url)
      .with(body: data)
      .to_return(status: 302, headers: {'Location' => result_location})
  end

  let(:code)            { 'print "hello, #{gets}"' }
  let(:stdin)           { "world" }
  let(:language)        { "ruby/mri-1.9.3" }
  let(:expected_data)   { {"utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => stdin} }
  let(:result_location) { 'https://eval.in/182584' }
  let(:url)             { "https://eval.in/" }

  it 'posts the data to eval_in with utf8, execute on, and the code/language/input forwarded through' do
    stub_eval_in expected_data
    EvalIn.post_code code, stdin: stdin, language: language
  end

  it 'defaults the user agent to its gem homepage' do
    stub_request(:post, url)
      .with(headers: {'User-Agent' => 'http://rubygems.org/gems/eval_in'})
      .to_return(status: 302, headers: {'Location' => result_location})
    EvalIn.post_code code, language: language
  end

  it 'can add a context to the user agent' do
    stub_request(:post, url)
      .with(headers: {'User-Agent' => 'http://rubygems.org/gems/eval_in (some context)'})
      .to_return(status: 302, headers: {'Location' => result_location})
    EvalIn.post_code code, language: language, context: 'some context'
  end

  it 'returns the redirect location jsonified' do
    stub_eval_in expected_data
    result = EvalIn.post_code code, stdin: stdin, language: language
    expect(result).to eq "#{result_location}.json"
  end

  it "Doesn't jsonify the redirect location if it already has a json suffix" do
    result_location << '.json'
    stub_eval_in expected_data
    result = EvalIn.post_code code, stdin: stdin, language: language
    expect(result).to eq result_location
  end

  it 'sets input to empty string if not provided' do
    stub_eval_in expected_data.merge('input' => '')
    EvalIn.post_code code, language: language
  end

  it 'raises an ArgumentError error if not given a language' do
    expect { EvalIn.post_code code, {} }.to raise_error ArgumentError, /language/
  end

  it 'can override the url' do
    url.replace "http://example.com"
    stub_eval_in
    EvalIn.post_code code, url: 'http://example.com', stdin: stdin, language: language
  end

  it 'supports basic http auth' do
    url.replace "http://user:pass@example.com"
    stub_eval_in
    EvalIn.post_code code, url: 'http://user:pass@example.com', stdin: stdin, language: language
  end

  context 'when it gets a non-redirect' do
    it 'informs user of language provided and languages known if language is unknown' do
      stub_request(:post, "https://eval.in/").to_return(status: 406)
      expect { EvalIn.post_code code, language: 'unknown-language' }.to \
        raise_error EvalIn::RequestError, /unknown-language.*?ruby\/mri-2.1/m
    end

    it 'just bubbles the existing error up if it knows the language' do
      stub_request(:post, "https://eval.in/").to_return(status: 406)
      expect { EvalIn.post_code code, language: 'ruby/mri-2.1' }.to \
        raise_error EvalIn::RequestError, /406/
    end
  end
end



RSpec.describe 'fetch_result_json' do
  include WebMock::API

  def stub_eval_in(options={})
    stub_request(:get,   options.fetch(:url))
      .to_return(status: options.fetch(:status, 200),
                 body:   options.fetch(:json_result, json_result))
  end

  let(:ruby_result) { {'lang' => 'some lang', 'lang_friendly' => 'some lang friendly', 'code' => 'some code', 'output' => 'some output', 'status' => 'some status'} }
  let(:json_result) { JSON.dump ruby_result }

  it 'queries the location, and inflates the json' do
    stub_eval_in(url: "http://example.com/some-result.json")
    result = EvalIn.fetch_result_json "http://example.com/some-result.json"
    expect(result).to match hash_including(ruby_result)
  end

  it 'raises an error when it gets a non-200' do
    stub_eval_in json_result: '', url: 'http://example.com'
    expect { EvalIn.fetch_result_json "http://example.com" }.to \
      raise_error EvalIn::ResultNotFound, %r(http://example.com)
  end

  it 'adds the url to the result' do
    stub_eval_in url: 'http://example.com'
    result = EvalIn.fetch_result_json 'http://example.com'
    expect(result['url']).to eq 'http://example.com'
  end
end


RSpec.describe 'build_result' do
  let(:language)          { 'some lang'          }
  let(:language_friendly) { 'some lang friendly' }
  let(:code)              { 'some code'          }
  let(:output)            { 'some output'        }
  let(:status)            { 'some status'        }
  let(:url)               { 'some url'           }
  let(:response_json)     { {'lang' => language, 'lang_friendly' => language_friendly, 'code' => code, 'output' => output, 'status' => status, 'url' => 'some url'} }

  it 'returns a response for the given response json' do
    result = EvalIn.build_result response_json
    assert_result result,
                  exitstatus:        0,
                  language:          language,
                  language_friendly: language_friendly,
                  code:              code,
                  output:            output,
                  status:            status,
                  url:               url
  end

  # exit:      https://eval.in/182586.json
  # raise:     https://eval.in/182587.json
  # in C:      https://eval.in/182588.json
  # Forbidden: https://eval.in/182599.json
  it 'sets the exit status to that of the program when it is available' do
    result = EvalIn.build_result response_json.merge('status' => "Exited with error status 123")
    expect(result.exitstatus).to eq 123
  end

  it 'sets the exit status to -1 when it is not available' do
    result = EvalIn.build_result response_json.merge('status' => nil)
    expect(result.exitstatus).to eq -1
  end

  it 'sets the exit status to 0 when the status does not imply a nonzero exit status' do
    result = EvalIn.build_result response_json.merge('status' => 'OK (0.012 sec real, 0.013 sec wall, 7 MB, 22 syscalls)')
    expect(result.exitstatus).to eq 0
  end

  it 'sets the exit status to 1 when there is an error' do
    result = EvalIn.build_result response_json.merge('status' => 'Forbidden access to file `/usr/local/bin/gem')
    expect(result.exitstatus).to eq 1
  end
end


RSpec.describe 'fetch_result' do
  include WebMock::API

  def stub_eval_in(url)
    stub_request(:get,   url)
      .to_return(status: 200, body: json_result)
  end

  let(:ruby_result) { {'lang' => 'some lang', 'lang_friendly' => 'some lang friendly', 'code' => 'some code', 'output' => 'some output', 'status' => 'some status'} }
  let(:json_result) { JSON.dump ruby_result }

  it 'wraps fetch_result_json and build_result' do
    url = 'https://eval.in/1.json'
    stub_eval_in url
    result = EvalIn.fetch_result url
    assert_result result,
                  exitstatus:        0,
                  language:          ruby_result['lang'],
                  language_friendly: ruby_result['lang_friendly'],
                  code:              ruby_result['code'],
                  output:            ruby_result['output'],
                  status:            ruby_result['status'],
                  url:               url
  end

  it 'jsonifies the url if it isn\'t already' do
    stub_eval_in 'https://eval.in/1.json'
    expect(EvalIn.fetch_result('https://eval.in/1').url).to      eq 'https://eval.in/1.json'
    expect(EvalIn.fetch_result('https://eval.in/1.json').url).to eq 'https://eval.in/1.json'
  end
end


RSpec.describe 'jsonify_url' do
  def assert_transforms(initial_url, expected_url)
    actual_url = EvalIn.jsonify_url(initial_url)
    expect(actual_url).to eq expected_url
  end

  it 'appends .json to a url that is missing it' do
    assert_transforms 'http://eval.in/1',          'http://eval.in/1.json'
    assert_transforms 'http://eval.in/1.json',     'http://eval.in/1.json'

    assert_transforms 'http://eval.in/1?a=b',      'http://eval.in/1.json?a=b'
    assert_transforms 'http://eval.in/1.json?a=b', 'http://eval.in/1.json?a=b'
  end

  it 'changes .not-json to .json' do
    assert_transforms 'http://eval.in/1.xml',      'http://eval.in/1.json'
    assert_transforms 'http://eval.in/1.html',     'http://eval.in/1.json'
    assert_transforms 'http://eval.in/1.html?a=b', 'http://eval.in/1.json?a=b'
  end
end
