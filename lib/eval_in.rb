# encoding: utf-8

require 'eval_in/http'
require 'eval_in/client'
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
    url = Client.post_code(code, options)
    fetch_result url, options
  end

  # @param url [String] the url with the result
  # @option options [String] :context Will be included in the user agent
  #
  # @example
  #   result = EvalIn.fetch_result "https://eval.in/147.json"
  #   result.output # => "Hello Charlie! "
  def self.fetch_result(raw_url, options={})
    raw_json_url = HTTP.jsonify_url(raw_url)
    Client.build_result Client.fetch_result_json(raw_json_url, options)
  end
end
