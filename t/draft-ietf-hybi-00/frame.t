#!/usr/bin/env perl

use strict;
use warnings;

use utf8;

use Test::More tests => 27;

use Encode;

use_ok 'Protocol::WebSocket::Frame';

my $f = Protocol::WebSocket::Frame->new(version => 'draft-ietf-hybi-00');

$f->append;
ok not defined $f->next;
$f->append('');
ok not defined $f->next;

$f->append('qwe');
ok not defined $f->next;
$f->append("\x00foo\xff");
is $f->next => 'foo';
ok not defined $f->next;

$f->append("\x00");
ok not defined $f->next;
$f->append("\xff");
is $f->next => '';

$f->append("\xff");
$f->append("\x00");
is $f->next => '';
ok $f->is_close;

$f->append("\x00");
ok not defined $f->next;
$f->append("foo");
$f->append("\xff");
is $f->next => 'foo';

$f->append("\x00foo\xff\x00bar\n\xff");
is $f->next => 'foo';
is $f->next => "bar\n";
ok not defined $f->next;

$f->append("123\x00foo\xff56\x00bar\xff789");
is $f->next => 'foo';
is $f->next => 'bar';
ok not defined $f->next;

my $frame = "123\x00foo\xff56\x00bar\xff789";
$f->append($frame);
is $f->next => 'foo';
is $f->next => 'bar';
ok not defined $f->next;
is $frame => '';

# We append bytes, but read characters
$f->append("\x00" . Encode::encode_utf8('☺') . "\xff");
is $f->next => '☺';

$f = Protocol::WebSocket::Frame->new(version => 'draft-ietf-hybi-00');
is $f->to_bytes => "\x00\xff";

#$f = Protocol::WebSocket::Frame->new(
#    buffer  => '123',
#    version => 'draft-ietf-hybi-00'
#);
#is $f->to_string => "\x00123\xff";

#$f = Protocol::WebSocket::Frame->new(
#    buffer  => '☺',
#    version => 'draft-ietf-hybi-00'
#);
#is $f->to_string => "\x00" . "☺" . "\xff";

#$f = Protocol::WebSocket::Frame->new(
#    buffer  => Encode::encode_utf8('☺'),
#    version => 'draft-ietf-hybi-00'
#);
#is $f->to_string => "\x00" . "☺" . "\xff";

# We pass characters, but send bytes
$f = Protocol::WebSocket::Frame->new(
    buffer  => '☺',
    version => 'draft-ietf-hybi-00'
);
is $f->to_bytes => "\x00" . Encode::encode_utf8("☺") . "\xff";

$f = Protocol::WebSocket::Frame->new(
    version => 'draft-ietf-hybi-00',
    type    => 'ping'
);
is $f->to_bytes => "\x00\xff";

$f = Protocol::WebSocket::Frame->new(
    version => 'draft-ietf-hybi-00',
    type    => 'close'
);
is $f->to_bytes => "\xff\x00";
