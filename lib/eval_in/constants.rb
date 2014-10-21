module EvalIn
  VERSION = '0.2.0'

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
end
