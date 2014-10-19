require 'spec_helper'
require 'eval_in/mock'


# TODO: look at other reasons the thing could blow up, do we need to provide the mock a way to do these things?
RSpec.describe EvalIn::Mock do
  specify 'instances provide the same methods with the same signatures as the EvalIn class' do
    mock = described_class.new
    EvalIn.methods(false).each do |method_name|
      expected_signature = EvalIn.method(method_name).parameters
      actual_signature   = mock.method(method_name).parameters
      expect(actual_signature).to eq expected_signature
    end
  end

  describe '#call' do
    context 'when initialized with a mock result' do
      it 'returns the mock result' do
        result = Object.new
        mock   = described_class.new result: result
        expect(mock.call "code", language: '').to equal result
      end
      it 'raises an ArgumentError if no language is provided' do
        mock = described_class.new result: Object.new
        expect { mock.call "code"               }.to     raise_error ArgumentError
        expect { mock.call "code", language: '' }.to_not raise_error
      end
    end

    context 'when initialized with an on_call proc' do
      it 'passes the code and options to the proc and returns the result' do
        mock = described_class.new on_call: -> code, options {
          expect(code).to eq 'on_call code'
          expect(options).to eq language: 'l'
          123
        }
        expect(mock.call "on_call code", language: "l").to eq 123
      end

      it 'raises an ArgumentError if no language is provided' do
        mock = described_class.new on_call: -> * {}
        expect { mock.call "code"               }.to     raise_error ArgumentError
        expect { mock.call "code", language: '' }.to_not raise_error
      end
    end

    context 'when initialized without a a result or on_call proc' do
      it 'executes the code with open3 against the list of language mappings' do
        mock = described_class.new(languages: {
          'correct-lang'   => {program: 'echo', args: ['RIGHT LANGUAGE']},
          'incorrect-lang' => {program: 'echo', args: ['WRONG LANGUAGE']},
        })
        result = mock.call 'some code', language: 'correct-lang'
        expect(result.output).to start_with 'RIGHT LANGUAGE'
      end

      def result_from(language: 'dummy language', code: 'dummy code', program_code: '# noop')
        described_class.new(languages: {
          language => {
            program: 'ruby',
            args:    ['-e', program_code]
          }
        }).call(code, language: language)
      end

      it 'records stderr and stdout' do
        result = result_from program_code: '$stdout.print("STDOUT "); $stdout.flush; $stderr.print("STDERR")'
        expect(result.output).to eq 'STDOUT STDERR'
      end

      it 'records the exit status' do
        expect(result_from(program_code: 'exit 12').exitstatus).to eq 12
        expect(result_from(program_code: 'exit 99').exitstatus).to eq 99
      end

      it 'sets the language and language_friendly to the provided language' do
        result = result_from language: 'the-lang'
        expect(result.language).to eq 'the-lang'
        expect(result.language_friendly).to eq 'the-lang'
      end

      it 'sets the code to the provided code' do
        expect(result_from(code: 'the-code').code).to eq 'the-code'
      end

      it 'sets the url to my mock result at https://eval.in/207744.json' do
        expect(result_from().url).to eq 'https://eval.in/207744.json'
      end

      it 'sets the status to something looking like a real status' do
        # in this case, just the status from https://eval.in/207744.json
        expect(result_from().status).to match success_status_regex
      end

      it 'blows up if asked for a language it doesn\'t know how to evaluate' do
        expect { described_class.new.call '', language: 'no-such-lang' }
          .to raise_error KeyError, /no-such-lang/
      end

      it 'raises an ArgumentError if no language is provided' do
        mock = described_class.new languages: {'l' => {program: 'echo', args: []}}
        expect { mock.call "code"                }.to     raise_error ArgumentError
        expect { mock.call "code", language: 'l' }.to_not raise_error
      end
    end
  end

  describe '#fetch_result' do
    context 'when initialized with a mock result' do
      it 'returns the mock result' do
        result = Object.new
        mock   = described_class.new(result: result)
        expect(mock.fetch_result "code").to equal result
      end
    end

    context 'when initialized with an on_fetch_result proc' do
      it 'passes the url and options to the proc and returns the result' do
        mock = described_class.new on_fetch_result: -> url, options {
          expect(url).to eq 'some url'
          expect(options).to eq a: 'b'
          123
        }
        expect(mock.fetch_result 'some url', a: 'b').to eq 123
      end
    end

    context 'when initialized without a result or on_fetch_result proc' do
      include WebMock::API

      it 'delegates to the real implementation' do
        url         = "http://example.com/some-result.json"
        result_hash = {'lang_friendly' => 'some lang friendly',
                       'lang'          => 'some lang',
                       'code'          => 'some code',
                       'output'        => 'some output',
                       'status'        => 'some status'}
        stub_request(:get, url)
          .with(headers: {'User-Agent' => 'http://rubygems.org/gems/eval_in (context)'})
          .to_return(status: 200, body: JSON.dump(result_hash))
        result = described_class.new.fetch_result("http://example.com/some-result.json", context: 'context')
        assert_result result,
                      exitstatus:        0,
                      language:          result_hash['lang'],
                      language_friendly: result_hash['lang_friendly'],
                      code:              result_hash['code'],
                      output:            result_hash['output'],
                      status:            result_hash['status'],
                      url:               url
      end
    end
  end
end
