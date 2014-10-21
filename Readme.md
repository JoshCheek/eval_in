[![Build Status](https://secure.travis-ci.org/JoshCheek/eval_in.png?branch=master)](http://travis-ci.org/JoshCheek/eval_in)

EvalIn
======

Safely evaluates code (Ruby and others) by sending it through https://eval.in

Example
-------

It's this simple:

```ruby
require 'eval_in'

result = EvalIn.call 'puts "hello, #{gets}"', stdin: 'world', language: "ruby/mri-2.1"

result.output             # => "hello, world\n"
result.exitstatus         # => 0
result.url                # => "https://eval.in/182711.json"
result.language           # => "ruby/mri-2.1"
result.language_friendly  # => "Ruby — MRI 2.1"
result.code               # => "puts \"hello, \#{gets}\""
result.status             # => "OK (0.064 sec real, 0.073 sec wall, 9 MB, 21 syscalls)"
```

Docs are [here](http://rdoc.info/gems/eval_in/frames/EvalIn).

What languages can this run?
----------------------------

<table>
  <tr>
    <th align="left">Ruby</th>
    </td>
    <td>
      ruby/mri-1.0<br />
      ruby/mri-1.8.7<br />
      ruby/mri-1.9.3<br />
      ruby/mri-2.0.0<br />
      ruby/mri-2.1<br />
    </td>
  </tr>
  <tr>
    <th align="left">C</th>
    </td>
    <td>
      c/gcc-4.4.3<br />
      c/gcc-4.9.1<br />
    </td>
  </tr>
  <tr>
    <th align="left">C++</th>
    </td>
    <td>
      c++/c++11-gcc-4.9.1<br />
      c++/gcc-4.4.3<br />
      c++/gcc-4.9.1<br />
    </td>
  </tr>
  <tr>
    <th align="left">CoffeeScript</th>
    </td>
    <td>
      coffeescript/node-0.10.29-coffee-1.7.1<br />
    </td>
  </tr>
  <tr>
    <th align="left">Fortran</th>
    </td>
    <td>
      fortran/f95-4.4.3<br />
    </td>
  </tr>
  <tr>
    <th align="left">Haskell</th>
    </td>
    <td>
      haskell/hugs98-sep-2006<br />
    </td>
  </tr>
  <tr>
    <th align="left">Io</th>
    </td>
    <td>
      io/io-20131204<br />
    </td>
  </tr>
  <tr>
    <th align="left">JavaScript</th>
    </td>
    <td>
      javascript/node-0.10.29<br />
    </td>
  </tr>
  <tr>
    <th align="left">Lua</th>
    </td>
    <td>
      lua/lua-5.1.5<br />
      lua/lua-5.2.3<br />
    </td>
  </tr>
  <tr>
    <th align="left">OCaml</th>
    </td>
    <td>
      ocaml/ocaml-4.01.0<br />
    </td>
  </tr>
  <tr>
    <th align="left">PHP</th>
    </td>
    <td>
      php/php-5.5.14<br />
    </td>
  </tr>
  <tr>
    <th align="left">Pascal</th>
    </td>
    <td>
      pascal/fpc-2.6.4<br />
    </td>
  </tr>
  <tr>
    <th align="left">Perl</th>
    </td>
    <td>
      perl/perl-5.20.0<br />
    </td>
  </tr>
  <tr>
    <th align="left">Python</th>
    </td>
    <td>
      python/cpython-2.7.8<br />
      python/cpython-3.4.1<br />
    </td>
  </tr>
  <tr>
    <th align="left">Slash</th>
    </td>
    <td>
      slash/slash-head<br />
    </td>
  </tr>
  <tr>
    <th align="left">x86 Assembly</th>
    </td>
    <td>
      assembly/nasm-2.07<br />
    </td>
  </tr>
</table>


Mocking for non-prod environments
---------------------------------

### Wiring the mock in

The mock that is provided will need to be set into place (its interface is in the next section).
If the code is directly doing `EvalIn.call(...)`, then it is
a hard dependency, and there is no ablity to set the mock into place.

You will need to structure your code such that it receives the `eval_in`
service as an argument, or looks it up in some configuration or something
(I strongly prefer the former).
This will allow your test environment to give it a mock that tests that it
works in all the edge cases, or is just generally benign (doesn't make real http request in tests),
your dev environment to give it an `EvalIn` that looks so close to the real one you wouldn't even know,
and your prod environment to give it the actual `EvalIn` that actually uses the service.

If this is still unclear, here is an example:

* [Here](https://github.com/JoshCheek/miniature-octo-ironman/blob/8197568668dc815643d9612c8cdae2e326d80f58/lib/app.rb#L41-44)
  we use whatever `EvalIn` was injected.
* [Here](https://github.com/JoshCheek/miniature-octo-ironman/blob/8197568668dc815643d9612c8cdae2e326d80f58/config.prod.ru#L18)
  we inject the real `EvalIn` for the prod environment.
* [Here](https://github.com/JoshCheek/miniature-octo-ironman/blob/8197568668dc815643d9612c8cdae2e326d80f58/config.ru#L33-35)
  we inject a mock that does evaluate code for the development environment.
* [Here](https://github.com/JoshCheek/miniature-octo-ironman/blob/8197568668dc815643d9612c8cdae2e326d80f58/features/support/our_helpers.rb#L74-77)
  we inject a mock result for the test environment.

### The provided mock

For a test or dev env where you don't care about correctness,
just that it does something that looks real,
you can make a mock that has a `Result`,
instantiated with any values you care about.

```ruby
require 'eval_in/mock'
eval_in = EvalIn::Mock.new(result: EvalIn::Result.new(code: 'injected code', output: 'the output')) 

eval_in.call('overridden code', language: 'irrelevant')
# => #<EvalIn::Result:0x007fb503a7a5e8
#     @code="injected code",
#     @exitstatus=-1,
#     @language="",
#     @language_friendly="",
#     @output="the output",
#     @status="",
#     @url="">
```

If you want your environment to behave approximately like the real `eval_in`,
you can instantiate a mock that knows how to evaluate code locally.
This is necessary, because it doesn't know how to execute these languages
(eval.in does that, it just knows how to talk to eval.in).
So you must provide it with a list of languages and how to execute them

This is probably idea for a dev environment, the results will be the most realistic.

**NOTE THAT THIS DOES NOT WORK ON JRUBY**

```ruby
require 'eval_in/mock'

# a mock that can execute Ruby code and C code
eval_in = EvalIn::Mock.new(languages: {
  'ruby/mri-2.1' => {program: RbConfig.ruby,
                     args: []
                    },
  'c/gcc-4.9.1'  => {program: RbConfig.ruby,
                     args: ['-e',
                            'system "gcc -x c -o /tmp/eval_in_c_example #{ARGV.first}"
                             exec   "/tmp/eval_in_c_example"']
                    },
})

eval_in.call 'puts "hello from ruby!"; exit 123', language: 'ruby/mri-2.1'
# => #<EvalIn::Result:0x007fb503a7d518
#     @code="puts \"hello from ruby!\"; exit 123",
#     @exitstatus=123,
#     @language="ruby/mri-2.1",
#     @language_friendly="ruby/mri-2.1",
#     @output="hello from ruby!\n",
#     @status="OK (0.072 sec real, 0.085 sec wall, 8 MB, 19 syscalls)",
#     @url="https://eval.in/207744.json">

eval_in.call '#include <stdio.h>
int main() {
  puts("hello from c!");
}', language: 'c/gcc-4.9.1'
# => #<EvalIn::Result:0x007fb503a850b0
#     @code="#include <stdio.h>\nint main() {\n  puts(\"hello from c!\");\n}",
#     @exitstatus=0,
#     @language="c/gcc-4.9.1",
#     @language_friendly="c/gcc-4.9.1",
#     @output="hello from c!\n",
#     @status="OK (0.072 sec real, 0.085 sec wall, 8 MB, 19 syscalls)",
#     @url="https://eval.in/207744.json">
```

You can also provide a callback that will be invoked to handle the request.
This is probably ideal for testing more nuanced edge cases that the mock
doesn't inherently provide the ability to do.

```ruby
require 'eval_in/mock'
eval_in = EvalIn::Mock.new on_call: -> code, options { raise EvalIn::RequestError, 'does my code do the right thing in the event of an exception?' }

eval_in.call('code', language: 'any') rescue $! # => #<EvalIn::RequestError: does my code do the right thing in the event of an exception?>
```

Attribution
-----------

Thanks to [Charlie Sommerville](https://twitter.com/charliesome) for making eval-in.

Thanks to Mon Oui, I partially stole the first version of the implementation from his gem [cinch-eval-in](http://rubygems.org/gems/cinch-eval-in)


Contributing
------------

Fork it, make your changes, send me a pull request.
Make sure your code is tested and all tests pass.

Run tests with `bundle exec rspec`, run integration tests with `bundle exec rspec -t integration`.


<a href="http://www.wtfpl.net/"><img src="http://www.wtfpl.net/wp-content/uploads/2012/12/wtfpl.svg" height="20" alt="WTFPL" /></a> License
-------


    Copyright (C) 2014 Josh Cheek <josh.cheek@gmail.com>

    This program is free software. It comes without any warranty,
    to the extent permitted by applicable law.
    You can redistribute it and/or modify it under the terms of the
    Do What The Fuck You Want To Public License,
    Version 2, as published by Sam Hocevar.
    See http://www.wtfpl.net/ for more details.
