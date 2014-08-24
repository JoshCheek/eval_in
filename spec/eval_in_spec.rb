require 'eval_in'
require 'webmock'
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.filter_run_excluding integration: true
end

RSpec.describe EvalIn, integration: true do
  it 'evaluates Ruby code through eval.in' do
    result = EvalIn.call 'print "hello, #{gets}"', stdin: "world", language: "ruby/mri-1.9.3"
    expect(result.exitstatus       ).to eq 0
    expect(result.language         ).to eq "ruby/mri-1.9.3"
    expect(result.language_friendly).to eq "Ruby — MRI 1.9.3"
    expect(result.code             ).to eq 'print "hello, #{gets}"'
    expect(result.output           ).to eq "hello, world"
    expect(result.status           ).to match /OK \([\d.]+ sec real, [\d.]+ sec wall, \d MB, \d+ syscalls\)/
  end
end

RSpec.describe EvalIn::Result do
  def assert_result(result, attributes)
    attributes.each do |key, value|
      expect(result.public_send key).to eq value
    end
  end

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
                  status:            ''
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
      .with(:body => data)
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

  it 'returns the redirect location jsonified' do
    result = EvalIn.post_code code, stdin: stdin, language: language
    expect(result).to eq "#{result_location}.json"
  end

  it 'sets input to empty string if not provided' do
    stub_eval_in expected_data.merge('input' => '')
    EvalIn.post_code code, language: language
  end

  it 'raises an ArgumentError error if not given a language' do
    expect { EvalIn.post_code code, {} }.to raise_error KeyError, /language/
  end

  it 'can override the url' do
    url.replace "http://example.com"
    stub_eval_in
    EvalIn.post_code code, url: 'http://example.com', stdin: stdin, language: language
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

get_response = <<RESPONSE
{"lang":"ruby/mri-1.9.3","lang_friendly":"Ruby — MRI 1.9.3","code":"print \"hello \#{gets}\"","output":"hello world","status":"OK (0.020 sec real, 0.024 sec wall, 7 MB, 41 syscalls)"}
RESPONSE

