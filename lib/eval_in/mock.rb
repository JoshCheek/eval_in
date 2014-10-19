require 'open3'
require 'tempfile'

module EvalIn
  class Mock
    def initialize(options={})
      @result    = options.fetch :result,    nil
      @languages = options.fetch :languages, {}
    end

    def call(code, options={})
      language_name = EvalIn.__send__ :language_or_error_from, options
      return @result if @result
      tempfile = Tempfile.new 'EvalIn mock'
      tempfile.write code
      tempfile.close
      lang    = @languages.fetch language_name
      program = lang.fetch(:program)
      args    = lang.fetch(:args, []) + [tempfile.path]
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

    def fetch_result(raw_url, options={})
      return @result if @result
      EvalIn.__send__ :fetch_result, raw_url, options
    end
  end
end
