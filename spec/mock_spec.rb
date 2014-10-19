require 'spec_helper'
require 'eval_in/mock'

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

    context 'when a mock result is not provided' do
      it 'executes the code with open3 against the list of language mappings' do
        mock = described_class.new(languages: {
          'correct-lang'   => {program: 'echo', args: ['RIGHT LANGUAGE']},
          'incorrect-lang' => {program: 'echo', args: ['WRONG LANGUAGE']},
        })
        result = mock.call 'some code', language: 'correct-lang'
        expect(result.output).to start_with 'RIGHT LANGUAGE'
      end

      def result_from(code: 'dummy code', program_code: '# noop')
        described_class.new(languages: {
          'the-language' => {
            program: 'ruby',
            args:    ['-e', program_code]
          }
        }).call(code, language: 'the-language')
      end

      it 'records stderr and stdout' do
        result = result_from program_code: '$stdout.print("STDOUT "); $stdout.flush; $stderr.print("STDERR")'
        expect(result.output).to eq 'STDOUT STDERR'
      end

      it 'records the exit status' do
        expect(result_from(program_code: 'exit 12').exitstatus).to eq 12
        expect(result_from(program_code: 'exit 99').exitstatus).to eq 99
      end

      it 'sets the language and language_Friendly to the provided language'
      it 'sets the code to the provided code'
      it 'sets the url to my mock result at https://eval.in/207744.json'
      it 'blows up if asked for a language it doesn\'t know how to evaluate'
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

    context 'when a mock result it not provided' do
      it 'fetches the requested result (delegates to the real implementation)'
      it 'raises ResultNotFound if it can\'t fidn one there'
    end
  end
end
