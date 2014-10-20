# encoding: utf-8
require 'spec_helper'


RSpec.describe EvalIn do
  describe 'integration tests', integration: true do
    around do |spec|
      WebMock.allow_net_connect!
      spec.call
      WebMock.disable_net_connect!
    end

    let(:context) { 'eval_in integration test' }

    it '.call evaluates Ruby code through eval.in' do
      result = EvalIn.call 'print "hello, #{gets}"', stdin: "world", language: "ruby/mri-2.1", context: context
      expect(result.exitstatus       ).to eq 0
      expect(result.language         ).to eq "ruby/mri-2.1"
      expect(result.language_friendly).to eq "Ruby — MRI 2.1"
      expect(result.code             ).to eq 'print "hello, #{gets}"'
      expect(result.output           ).to eq "hello, world"
      expect(result.status           ).to match success_status_regex
      expect(result.url              ).to match %r(https://eval.in/\d+.json)
    end

    it '.fetch_result fetches previous results from eval.in' do
      result = EvalIn.fetch_result "https://eval.in/147.json"
      expect(result.exitstatus       ).to eq 0
      expect(result.language         ).to eq "ruby/mri-1.9.3"
      expect(result.language_friendly).to eq "Ruby — MRI 1.9.3"
      expect(result.code             ).to eq %'class Greeter\r\n  def initialize(name)\r\n    @name = name\r\n  end\r\n\r\n  def greet\r\n    puts \"Hello \#{@name}!\"\r\n  end\r\nend\r\n\r\ngreeter = Greeter.new \"Charlie\"\r\ngreeter.greet'
      expect(result.output           ).to eq "Hello Charlie!\n"
      expect(result.status           ).to match success_status_regex
      expect(result.url              ).to match %r(https://eval.in/147.json)
    end

    it 'is in sync with known languages' do
      # iffy solution, but it's simple and works,
      # Rexml might get taken out of stdlib, so is more likely than this regex to fail in the future,
      # and I don't want to add dep on Nokogiri (w/ libxml & libxslt) where a small regex works adequately
      current_known_languages = EvalIn::HTTP.get_request('https://eval.in', context)
                                            .body
                                            .each_line
                                            .map { |line| line[/option.*?value="([^"]+)"/, 1] }
                                            .compact
      expect(EvalIn::KNOWN_LANGUAGES).to eq current_known_languages
    end
  end


  describe '.fetch_result' do
    include WebMock::API

    def stub_eval_in(url, options={})
      stub_request(:get, url)
        .with(headers: {'User-Agent' => options.fetch(:user_agent, 'http://rubygems.org/gems/eval_in')})
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

    it 'can take a context for the user agent' do
      stub_eval_in 'https://eval.in/1.json', user_agent: 'http://rubygems.org/gems/eval_in (c)'
      expect(EvalIn.fetch_result('https://eval.in/1', context: 'c').url).to eq 'https://eval.in/1.json'
    end
  end
end
