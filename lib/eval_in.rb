require 'uri'
require 'json'
require 'net/http'
require 'eval_in/version'

module EvalIn
  RequestError = Class.new StandardError

  KNOWN_LANGUAGES = %w[
    c/gcc-4.4.3
    c/gcc-4.9.1
    c++/c++11-gcc-4.9.1
    c++/gcc-4.4.3
    c++/gcc-4.9.1
    coffeescript/node-0.10.29-coffee-1.7.1
    fortran/f95-4.4.3
    haskell/hugs98-sep-2006
    io/io-20131204
    javascript/node-0.10.29
    lua/lua-5.1.5
    lua/lua-5.2.3
    ocaml/ocaml-4.01.0
    php/php-5.5.14
    pascal/fpc-2.6.4
    perl/perl-5.20.0
    python/cpython-2.7.8
    python/cpython-3.4.1
    ruby/mri-1.0
    ruby/mri-1.8.7
    ruby/mri-1.9.3
    ruby/mri-2.0.0
    ruby/mri-2.1
    slash/slash-head
    assembly/nasm-2.07
  ]

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
    build_result get_code post_code(code, options)
  end

  def self.post_code(code, options)
    uri       = URI(options.fetch(:url, "https://eval.in/"))
    input     = options.fetch(:stdin, "")
    language  = options.fetch(:language)
    result    = Net::HTTP.post_form(uri, "utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => input)
    if result.code == '302'
      location  = result['location']
      location += '.json' unless location.end_with? '.json'
      location
    elsif KNOWN_LANGUAGES.include? language
      raise RequestError, "There was an unexpected error, we got back a response code of #{result.code}"
    else
      raise RequestError, "Perhaps language is wrong, you provided: #{language.inspect}\n"\
                          "Known languages are: #{KNOWN_LANGUAGES.inspect}"
    end
  end

  def self.get_code(location)
    location = URI(location) unless location.kind_of? URI
    body     = Net::HTTP.get(location)
    result   = JSON.parse body
    result.each_with_object({}) do |(key, value), symbolized_result|
      symbolized_result[key.intern] = value
    end
  end

  def self.build_result(response_json)
    status = 0
    Result.new exitstatus:          status,
               language:            response_json.fetch(:lang),
               language_friendly:   response_json.fetch(:lang_friendly),
               code:                response_json.fetch(:code),
               output:              response_json.fetch(:output),
               status:              response_json.fetch(:status)
  end
end
