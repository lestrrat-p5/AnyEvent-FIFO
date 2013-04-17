use strict;
use Test::More (tests => 41);
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
	is( $q->active, 1, "1 task is running" );
	is( $q->waiting, 10 - $i, "$i tasks is waiting" );
        $cv->end
    }, $i );
}

$cv->recv;
