# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eval_in/version"

Gem::Specification.new do |s|
  s.name        = "eval_in"
  s.version     = EvalIn::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/eval_in"
  s.summary     = %q{Evaluates code (Ruby and others) safely by sending it to https://eval.in}
  s.description = <<-DESCRIPTION.gsub(/^  /, '')
  Safely evaluates code (Ruby and others) by sending it through https://eval.in

  == Languages and Versions

    Ruby          | MRI 1.0, MRI 1.8.7, MRI 1.9.3, MRI 2.0.0, MRI 2.1
    C             | GCC 4.4.3, GCC 4.9.1
    C++           | C++11 (GCC 4.9.1), GCC 4.4.3, GCC 4.9.1
    CoffeeScript  | CoffeeScript 1.7.1 (Node 0.10.29)
    Fortran       | F95 (GCC 4.4.3)
    Haskell       | Hugs98 September 2006
    Io            | Io 20131204
    JavaScript    | Node 0.10.29
    Lua           | Lua 5.1.5, Lua 5.2.3
    OCaml         | OCaml 4.01.0
    PHP           | PHP 5.5.14
    Pascal        | Free Pascal 2.6.4
    Perl          | Perl 5.20.0
    Python        | CPython 2.7.8, CPython 3.4.1
    Slash         | Slash HEAD
    x86 Assembly  | NASM 2.07

  == Example:

  It's this simple:

    result = EvalIn.call 'puts "example"', language: "ruby/mri-2.1"
    result.output # returns "example\\n"

  DESCRIPTION
  s.license     = "WTFPL"

  s.files         = `git ls-files`.split("\n") - ['docs/seeing is believing.psd'] # remove psd b/c it boosts the gem size from 50kb to 20mb O.o
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec',   '~> 3.0'
  s.add_development_dependency 'webmock', '~> 1.18'
end
