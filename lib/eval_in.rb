require 'uri'
require 'json'
require 'net/http'

class EvalIn
  class Result
    attr_accessor :exitstatus, :language, :language_friendly, :code, :output, :status

    def initialize(attributes={})
      attributes = attributes.dup
      self.exitstatus         = attributes.delete(:exitstatus)        || -1
      self.language           = attributes.delete(:language)          || ""
      self.language_friendly  = attributes.delete(:language_friendly) || ""
      self.code               = attributes.delete(:code)              || ""
      self.output             = attributes.delete(:output)            || ""
      self.status             = attributes.delete(:status)            || ""
      $stderr.puts "Unexpected attributes! #{attributes.keys.inspect}" if attributes.any?
    end
  end

  def self.call(code, options={})
    BuildResult.call GetCode.call PostCode.call(code, options)
  end

  module PostCode
    def self.call(code, options)
      uri       = options.fetch(:url, "https://eval.in/")
      uri       = URI(uri) unless uri.kind_of? URI
      input     = options.fetch(:stdin, "")
      language  = options.fetch(:language)
      result    = Net::HTTP.post_form(uri, "utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => input)
      location  = result['location']
      location += '.json' unless location.end_with? '.json'
      location
    end
  end

  module GetCode
    def self.call(location)
      location = URI(location) unless location.kind_of? URI
      body     = Net::HTTP.get(location)
      result   = JSON.parse body
      result.each_with_object({}) do |(key, value), symbolized_result|
        symbolized_result[key.intern] = value
      end
    end
  end

  module BuildResult
    def self.call(response_json)
      status = 0
      Result.new exitstatus:          status,
                 language:            response_json.fetch(:lang),
                 language_friendly:   response_json.fetch(:lang_friendly),
                 code:                response_json.fetch(:code),
                 output:              response_json.fetch(:output),
                 status:              response_json.fetch(:status)
    end
  end

end
