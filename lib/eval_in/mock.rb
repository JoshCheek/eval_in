require 'open3'
require 'tempfile'

module EvalIn
  class Mock
    def initialize(options={})
      @result    = options.fetch :result,    nil
      @languages = options.fetch :languages, {}
    end

    def call(code, options={})
      return @result if @result
      lang = @languages.fetch options.fetch(:language)
      tempfile = Tempfile.new 'EvalIn mock'
      tempfile.write code
      tempfile.close
      program = lang.fetch(:program)
      args    = lang.fetch(:args, []) + [tempfile.path]
      out, exitstatus = Open3.capture2e(program, *args)
      tempfile.unlink
      Result.new output: out
    end

    def fetch_result(raw_url, options={})
      @result
    end
  end
end
