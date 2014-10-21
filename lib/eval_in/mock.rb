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
      out, status = open_process_capture_out_and_error(program, args)
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

    def open_process_capture_out_and_error(program, args)
      Open3.capture2e(program, *args)
    end

    # I legit tried for a couple of hours to get this to work on JRuby, this is attempt 1, it blows up b/c Kernel#spawn won't take in/out/err on JRuby
    #   # Defining it myself since JRuby doesn't seem to implement Open3.capture2e correctly
    #   # Implementation stolen and modified from numerous functions here:
    #   #   https://github.com/ruby/ruby/blob/622f31be31b43429dfebe85e8f5bc5c92af5dd1f/lib/open3.rb#L318-351
    #   def open_process_capture_out_and_error(program, args)
    #     in_r,  in_w  = IO.pipe
    #     out_r, out_w = IO.pipe
    #     in_w.sync    = true
    #     pid = spawn(program, *args, in: in_r, out: out_w, err: out_w)
    #     in_r.close
    #     out_w.close
    #     output = out_r.read
    #     Process.wait pid
    #     [output, $?]
    #   ensure
    #     in_w.close
    #     out_r.close
    #   end
    #
    # This was attempt 2, it blows up b/c I cannot fucking figure out how to get the exit status
    # def open_process_capture_out_and_error(program, args)
    #   if IO.respond_to? :popen4
    #     pid, stdin, stdout, stderr = IO.popen4('c:\ruby187\bin\ruby.exe')
    #     [stdout.read, $?]
    #   else
    #     Open3.capture2e(program, *args)
    #   end
    # end
  end
end
