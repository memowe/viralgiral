ViralGiral
==========

Builder for viral web "games".

[![Travis CI tests](https://travis-ci.org/memowe/viralgiral.svg?branch=master)](https://travis-ci.org/memowe/viralgiral)
[![Codecov test coverage](https://codecov.io/gh/memowe/viralgiral/branch/master/graph/badge.svg)](https://codecov.io/gh/memowe/viralgiral)
[![Coveralls test coverage](https://coveralls.io/repos/github/memowe/viralgiral/badge.svg?branch=master)](https://coveralls.io/github/memowe/viralgiral?branch=master)

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

plugin ViralGiral => {
    data_filename   => '/path/to/storage_file.data',    # default: ./VG_data
    prefix          => 'foo',                           # default: ''
};

# Viral "games" routes generated.
# ViralGiral::Data helper available.

get '/inspect_entity/:uuid' => sub ($c) {
    my $e = $c->viralgiral_data->get_entity($c->param('uuid'));
    $c->render(text => $c->dumper($e));
};

app->start;
```

Prerequisites
-------------

**[Perl 5.20][perl]**

| Module | Version |
|--------|--------:|
| [Clone][clone] | 0.39 |
| [EventStore::Tiny][evstti] | 0.6 |
| [Mojolicious][mojo] | 7.93 |
| [UUID::Tiny][uuti] | 1.04 |
| [*Test::Exception*][teex]<br>(Tests only) | 0.43 |

[perl]: https://www.perl.org/get.html
[clone]: https://metacpan.org/pod/Clone
[evstti]: https://metacpan.org/pod/EventStore::Tiny
[mojo]: https://metacpan.org/pod/Mojolicious
[uuti]: https://metacpan.org/pod/UUID::Tiny
[teex]: https://metacpan.org/pod/Test::Exception

License and copyright
---------------------

Copyright (c) 2018 [Mirko Westermeier][mirko] ([mirko@westermeier.de][mmail])

[mirko]: http://mirko.westermeier.de
[mmail]: mailto:mirko@westermeier.de

This library is distributed under the MIT (X11) License:

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

