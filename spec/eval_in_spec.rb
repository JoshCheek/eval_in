require 'eval_in'

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
