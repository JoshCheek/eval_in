require 'spec_helper'

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

  it 'logs extra attributes to stderr input' do
    fake_error_stream = StringIO.new
    EvalIn::Result.new a: 1, b: 2, stderr: fake_error_stream
    expect(fake_error_stream.string).to eq "Unexpected attributes! [:a, :b]\n"
  end

  it 'defaults the error stream to $stderr' do
    expect { EvalIn::Result.new a: 1, b: 2 }.to \
      output("Unexpected attributes! [:a, :b]\n").to_stderr
  end

  it 'has an as_json representation which dumps all its keys' do
    result = EvalIn::Result.new(language:          'l',
                                language_friendly: 'lf',
                                code:              'c',
                                output:            'o',
                                status:            's',
                                url:               'u')
    expect(result.as_json).to eq 'exitstatus'        => -1,
                                 'language'          => 'l',
                                 'language_friendly' => 'lf',
                                 'code'              => 'c',
                                 'output'            => 'o',
                                 'status'            => 's',
                                 'url'               => 'u'
  end

  it 'has a to_json that works correctly' do
    result = EvalIn::Result.new(language:          'l',
                                language_friendly: 'lf',
                                code:              'c',
                                output:            'o',
                                status:            's',
                                url:               'u')
    after_json = JSON.parse(result.to_json)
    expect(after_json).to eq 'exitstatus'        => -1,
                             'language'          => 'l',
                             'language_friendly' => 'lf',
                             'code'              => 'c',
                             'output'            => 'o',
                             'status'            => 's',
                             'url'               => 'u'
  end
end
