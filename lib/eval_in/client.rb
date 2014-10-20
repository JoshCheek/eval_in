require 'json'

module EvalIn

  # Code that does the integration with the actual eval.in service
  # It is primarily in place to help the toplevel methods wire things together
  # in the ways that they need to.
  #
  # **This should be assumed volatile, and you should avoid depending on it.**
  module Client
    extend self

    # @api private
    def post_code(code, options)
      url        = options.fetch(:url, "https://eval.in/")
      input      = options.fetch(:stdin, "")
      language   = language_or_error_from options
      form_data  = {"utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => input}

      result = HTTP.post_request url, form_data, user_agent_for(options[:context])

      if result.code == '302'
        HTTP.jsonify_url result['location']
      elsif KNOWN_LANGUAGES.include? language
        raise RequestError, "There was an unexpected error, we got back a response code of #{result.code}"
      else
        raise RequestError, "Perhaps language is wrong, you provided: #{language.inspect}\n"\
                            "Known languages are: #{KNOWN_LANGUAGES.inspect}"
      end
    end

    # @api private
    def fetch_result_json(raw_url, options={})
      result = HTTP.get_request raw_url, user_agent_for(options[:context])
      return JSON.parse(result.body).merge('url' => raw_url) if result.body
      raise ResultNotFound, "No json at #{raw_url.inspect}"
    end

    # @api private
    def build_result(response_json)
      exitstatus = case response_json['status']
                   when nil             then nil # let Result choose default
                   when /status (\d+)$/ then $1.to_i
                   when /^Forbidden/    then 1
                   else                      0
                   end

      Result.new exitstatus:          exitstatus,
                 language:            response_json['lang'],
                 language_friendly:   response_json['lang_friendly'],
                 code:                response_json['code'],
                 output:              response_json['output'],
                 status:              response_json['status'],
                 url:                 response_json['url']
    end

    # @api private
    def user_agent_for(context)
      'http://rubygems.org/gems/eval_in'.tap do |agent|
        agent << " (#{context})" if context
      end
    end

    # @api private
    def language_or_error_from(options)
      options.fetch :language do
        raise ArgumentError, ":language is mandatory, but options only has #{options.keys.inspect}"
      end
    end

  end
end
