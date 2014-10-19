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
        mock   = described_class.new(result: result)
        expect(mock.call "code").to equal result
      end
    end

    context 'when a mock result is not provided' do
      it 'executes the code with open3 against the list of language mappings'
      it 'records stderr and stdout'
      it 'records the exit status'
      it 'sets the language and language_Friendly to the provided language'
      it 'sets the code to the provided code'
      it 'sets the url to my mock result at https://eval.in/207744.json'
      it 'blows up if asked for a language it doesn\'t know how to evaluate'
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
    end
  end
end
