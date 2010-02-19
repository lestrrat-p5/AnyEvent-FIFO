use strict;
use Test::More (tests => 21);
use AnyEvent;

use_ok "AnyEvent::FIFO";

my $cv = AE::cv;

my $q = AnyEvent::FIFO->new();

my $expected = 1;
foreach my $i (1..10) {
    $cv->begin;
    $q->push( sub {
        my ($guard, @args) = @_;
        is( $args[0], $i, "arg is $i" );
        is( $i, $expected++, "$i-th execution" );
        $cv->end
    }, $i );
}

$cv->recv;