require 'open3'
require 'tempfile'
require 'eval_in'
require 'eval_in/client'
require 'eval_in/result'

module EvalIn
  class Mock
    def initialize(options={})
      @result          = options.fetch :result,          nil
      @languages       = options.fetch :languages,       Hash.new
      @on_call         = options.fetch(:on_call)         { lambda { |*args| @result || evaluate_with_tempfile(*args) } }
      @on_fetch_result = options.fetch(:on_fetch_result) { lambda { |*args| @result || EvalIn.fetch_result(*args)    } }
    end

    def call(code, options={})
      language_name = EvalIn::Client.language_or_error_from options
      @on_call.call(code, options)
    end

    def fetch_result(raw_url, options={})
      @on_fetch_result.call(raw_url, options)
    end

    private

    def evaluate_with_tempfile(code, options={})
      language_name = EvalIn::Client.language_or_error_from options
      tempfile      = Tempfile.new 'EvalIn-mock'
      tempfile.write code
      tempfile.close
      lang          = @languages.fetch language_name
      program       = lang.fetch(:program)
      args          = lang.fetch(:args, []) + [tempfile.path]
      out, status = Open3.capture2e(program, *args)
      Result.new output:            out,
                 exitstatus:        status.exitstatus,
                 language:          language_name,
                 language_friendly: language_name,
                 code:              code,
                 url:               'https://eval.in/207744.json',
                 status:            'OK (0.072 sec real, 0.085 sec wall, 8 MB, 19 syscalls)'
    ensure
      tempfile.unlink if tempfile
    end
  end
end
