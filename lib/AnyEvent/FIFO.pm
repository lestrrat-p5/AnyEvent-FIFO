package AnyEvent::FIFO;
use strict;
use AnyEvent;
use AnyEvent::Util ();

our $VERSION = '0.00002';

sub new {
    my $class = shift;
    bless {
        max_active => 1,
        @_,
        active => {},
        events => {},
    }, $class;
}

sub push {
    my ($self, $slot, $cb, @args) = @_;
    # the first argument must be the name of the slot or a callback
    # if no callback is specified, then 
    if (ref $slot) {
        unshift @args, $cb;
        $cb = $slot;
        $slot = "__default__";
    }

    push @{$self->{events}->{$slot}}, [$cb, @args];

    # XXX is it OK to rely on idle? Is there a possibility we might be
    # asked to wait for a very long time?
    my $idle; $idle = AE::idle sub {
        undef $idle;
        $self->drain();
    };
}

sub drain {
    my $self = shift;

    my @slots = keys %{$self->{events}};
    my $dispatched = 1;
    while ($dispatched) {
        $dispatched = 0;
        foreach my $slot (@slots) {
            my $events = $self->{events}->{$slot};
            if ( @$events && ($self->{active}->{$slot} ||= 0) < $self->{max_active} ) {
                $dispatched++;
                my $stuff = shift @$events;
                my ($cb, @args) = @$stuff;
                $self->{active}->{$slot}++;
                $cb->( AnyEvent::Util::guard {
                    $self->{active}->{$slot}--;
                    if ($self->{active}->{$slot} <= 0) {
                        delete $self->{active}->{$slot};
                    }
                    my $idle; $idle = AE::idle sub {
                        undef $idle;
                        $self->drain();
                    };
                }, @args );
            }
        }
    }
}

1;

__END__

=head1 NAME

AnyEvent::FIFO - Simple FIFO Callback Dispatch

=head1 SYNOPSIS

    my $fifo = AnyEvent::FIFO->new(
        max_active => 1, # max "concurrent" callbacks to execute per slot
    );

    # send to the "default" slot
    $fifo->push( \&callback, @args );

    # send to the "slot" slot
    $fifo->push( "slot", \&callback, @args );

    # dispatch is done automatically

    sub callback {
        my ($guard, @args) = @_;

        # next callback will be executed when $guard is undef'ed or
        # when it goes out of scope
    }

=head1 DESCRIPTION

AnyEvent::FIFO is a simple FIFO queue to dispatch events in order. 

If you use regular watchers and register callbacks from various places in
your program, you're not necessarily guaranteed that the callbacks will be 
executed in the order that you expect. By using this module, you can
register callbacks and they will be executed in that particular order.

=head1 METHODS

=head2 new

=over 4

=item max_active => $number

Number of concurrent callbacks to be executed B<per slot>.

=back

=head2 push ([$slot,] $cb [,@args])

=over 4

=item $slot

The name of the slot that this callback should be registered to. If $slot is
not specified, "__default__" is used.

=item $cb

The callback to be executed. Receives a "guard" object, and a list of arguments, as specied in @args.

$guard is the actually trigger that kicks the next callback to be executed, so you should keep it "alive" while you need it. For example, if you need to make an http request to declare the callback done, you should do something like this:

    $fifo->push( sub {
        my ($guard, @args) = @_;

        http_get $uri, sub {
            ...
            undef $guard; # *NOW* the callback is done
        }
    } );

=item @args

List of extra arguments that gets passed to the callback

=back

=head2 drain

Attemps to drain the queue, if possible. You DO NOT need to call this method
by yourself. It's handled automatically

=head1 AUTHOR

This module is basically a generalisation of the FIFO queue used in AnyEvent::HTTP by Marc Lehman. 

(c) Daisuke Maki C< <<daisuke@endeworks.jp>> > 2010

=cut