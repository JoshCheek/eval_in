# encoding: utf-8

require 'uri'
require 'json'
require 'net/http'
require 'pathname'
require 'eval_in/version'

module EvalIn
  EvalInError    = Class.new StandardError
  RequestError   = Class.new EvalInError
  ResultNotFound = Class.new EvalInError

  # @example Generated with
  #   nokogiri https://eval.in -e 'puts $_.xpath("//option/@value")'
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

  # The data structure containing the final result
  # its attributes default to null-objects for their given type
  class Result
    @attribute_names = [:exitstatus, :language, :language_friendly, :code, :output, :status, :url].freeze
    attr_accessor *@attribute_names
    class << self
      attr_reader :attribute_names
    end

    def initialize(attributes={})
      attributes = attributes.dup
      self.exitstatus         = attributes.delete(:exitstatus)        || -1
      self.language           = attributes.delete(:language)          || ""
      self.language_friendly  = attributes.delete(:language_friendly) || ""
      self.code               = attributes.delete(:code)              || ""
      self.output             = attributes.delete(:output)            || ""
      self.status             = attributes.delete(:status)            || ""
      self.url                = attributes.delete(:url)               || ""
      stderr                  = attributes.delete(:stderr)            || $stderr
      stderr.puts "Unexpected attributes! #{attributes.keys.inspect}" if attributes.any?
    end

    # Returns representation of the result built out of JSON primitives (hash, string, int)
    def as_json
      self.class.attribute_names.each_with_object Hash.new do |name, attributes|
        attributes[name.to_s] = public_send name
      end
    end

    def to_json
      JSON.dump(as_json)
    end
  end

  # @param code [String] the code to evaluate.
  # @option options [String] :language Mandatory, a language recognized by eval.in, such as any value in {KNOWN_LANGUAGES}.
  # @option options [String] :url      Override the url to post the code to
  # @option options [String] :stdin    Will be passed as standard input to the script
  # @option options [String] :context  Will be included in the user agent
  # @return [Result] the relevant data from the evaluated code.
  #
  # @example
  #   result = EvalIn.call 'puts "hello, #{gets}"', stdin: 'world', language: "ruby/mri-2.1"
  #   result.output # => "hello, world\n"
  def self.call(code, options={})
    url = post_code(code, options)
    fetch_result url, options
  end

  # @param url [String] the url with the result
  # @option options [String] :context Will be included in the user agent
  #
  # @example
  #   result = EvalIn.fetch_result "https://eval.in/147.json"
  #   result.output # => "Hello Charlie! "
  def self.fetch_result(raw_url, options={})
    raw_json_url = jsonify_url(raw_url)
    build_result fetch_result_json(raw_json_url, options)
  end

  # @api private
  def self.post_code(code, options)
    url        = options.fetch(:url, "https://eval.in/")
    input      = options.fetch(:stdin, "")
    language   = options.fetch(:language) { raise ArgumentError, ":language is mandatory, but options only has #{options.keys.inspect}" }
    form_data  = {"utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => input}

    result = post_request url, form_data, user_agent_for(options[:context])

    if result.code == '302'
      jsonify_url result['location']
    elsif KNOWN_LANGUAGES.include? language
      raise RequestError, "There was an unexpected error, we got back a response code of #{result.code}"
    else
      raise RequestError, "Perhaps language is wrong, you provided: #{language.inspect}\n"\
                          "Known languages are: #{KNOWN_LANGUAGES.inspect}"
    end
  end

  # @api private
  def self.fetch_result_json(raw_url, options={})
    result = get_request raw_url, user_agent_for(options[:context])
    return JSON.parse(result.body).merge('url' => raw_url) if result.body
    raise ResultNotFound, "No json at #{raw_url.inspect}"
  end

  # @api private
  def self.build_result(response_json)
    exitstatus = case response_json['status']
                 when nil             then nil # let it choose default
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
  def self.jsonify_url(url)
    uri = URI(url)
    uri.path = Pathname.new(uri.path).sub_ext('.json').to_s
    uri.to_s
  end

  # @private
  def self.user_agent_for(context)
    'http://rubygems.org/gems/eval_in'.tap do |agent|
      context && agent.concat(" (#{context})")
    end
  end

  # @api private
  # Can't just use Net::HTTP.get, b/c it doesn't use ssl on 1.9.3
  # https://github.com/ruby/ruby/blob/v2_1_2/lib/net/http.rb#L478-479
  # https://github.com/ruby/ruby/blob/v1_9_3_547/lib/net/http.rb#L454
  def self.get_request(raw_url, user_agent)
    generic_request_for raw_url:      raw_url,
                        request_type: Net::HTTP::Get,
                        user_agent:   user_agent
  end

  # @private
  def self.post_request(raw_url, form_data, user_agent)
    generic_request_for raw_url:      raw_url,
                        request_type: Net::HTTP::Post,
                        user_agent:   user_agent,
                        form_data:    form_data
  end

  # @private
  # stole this out of implementation for post_form https://github.com/ruby/ruby/blob/2afed6eceff2951b949db7ded8167a75b431bad6/lib/net/http.rb#L503
  # can use this to view the request: http.set_debug_output $stdout
  def self.generic_request_for(params)
    uri                   = URI params.fetch(:raw_url)
    path                  = uri.path
    path                  = '/' if path.empty?
    request               = params.fetch(:request_type).new(path)
    request['User-Agent'] = params[:user_agent] if params.key? :user_agent
    request.form_data     = params[:form_data]  if params.key? :form_data
    request.basic_auth uri.user, uri.password   if uri.user
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) { |http| http.request request }
  end
end
