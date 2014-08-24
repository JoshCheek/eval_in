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


What languages can this run?
----------------------------

<table>
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

Attribution
-----------

Thanks to [Charlie Sommerville](https://twitter.com/charliesome) for making eval-in.

Thanks to Mon Oui, I partially stole the implementation from his gem [cinch-eval-in](http://rubygems.org/gems/cinch-eval-in)


License
-------

              DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
     TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

    0. You just DO WHAT THE FUCK YOU WANT TO.

No Warranty
-----------

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

