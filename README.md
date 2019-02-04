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
    prefix          => 'foo',                           # default: 'vg'
    introspection   => 1,                               # default: undef
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
| *[Test::Exception][teex] (Tests only)* | *0.43* |
| *[Test::Mojo::CommandOutputRole][tmcor] (Tests only)*<br>*as a submodule* | *0.01* |

[perl]: https://www.perl.org/get.html
[clone]: https://metacpan.org/pod/Clone
[evstti]: https://metacpan.org/pod/EventStore::Tiny
[mojo]: https://metacpan.org/pod/Mojolicious
[uuti]: https://metacpan.org/pod/UUID::Tiny
[teex]: https://metacpan.org/pod/Test::Exception
[tmcor]: https://github.com/memowe/Test-Mojo-CommandOutputRole

License and copyright
---------------------

Copyright (c) 2018-2019 [Mirko Westermeier][mirko] ([\@memowe][mgh], [mirko@westermeier.de][mmail])

Released under the MIT (X11) license. See [LICENSE.txt][mit] for details.

[mirko]: http://mirko.westermeier.de
[mgh]: https://github.com/memowe
[mmail]: mailto:mirko@westermeier.de
[mit]: LICENSE.txt
