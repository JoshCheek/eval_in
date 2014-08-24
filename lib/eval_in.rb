require 'uri'
require 'json'
require 'net/http'
require 'eval_in/version'

module EvalIn
  EvalInError    = Class.new StandardError
  RequestError   = Class.new EvalInError
  ResultNotFound = Class.new EvalInError

  # curl https://eval.in | ruby -rnokogiri -e 'puts Nokogiri::HTML($stdin.read).css("option").map { |o| o["value"] }'
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
    uri      = URI(options.fetch(:url, "https://eval.in/"))
    input    = options.fetch(:stdin, "")
    language = options.fetch(:language)
    path     = uri.path
    path     = '/' if path.empty?

    # stole this out of implementation for post_form https://github.com/ruby/ruby/blob/trunk/lib/net/http.rb#L503
    request = Net::HTTP::Post.new(path)
    request.form_data = {"utf8" => "√", "code" => code, "execute" => "on", "lang" => language, "input" => input}
    request['User-Agent'] = 'http://rubygems.org/gems/eval_in'
    req.basic_auth uri.user, uri.password if uri.user
    net = Net::HTTP.new(uri.hostname, uri.port)
    # net.set_debug_output $stdout
    result = Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) { |http|
      http.request(request)
    }

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
    if body = Net::HTTP.get(URI location)
      JSON.parse body
    else
      raise ResultNotFound, "No json at #{location.inspect}"
    end
  end

  def self.build_result(response_json)
    status     = response_json['status']
    exitstatus = if    !status                   then nil # let it choose default
                 elsif status =~ /status (\d+)$/ then $1.to_i
                 elsif status =~ /^Forbidden/    then 1
                 else                                 0
                 end

    Result.new exitstatus:          exitstatus,
               language:            response_json['lang'],
               language_friendly:   response_json['lang_friendly'],
               code:                response_json['code'],
               output:              response_json['output'],
               status:              response_json['status']
  end
end
