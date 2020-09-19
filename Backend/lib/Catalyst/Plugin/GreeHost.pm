package Catalyst::Plugin::GreeHost;
use warnings;
use strict;
use Scalar::Util qw( looks_like_number );
use DateTime::TimeZone;
use Try::Tiny;

sub process_body_data {
    my ( $c, @opts ) = @_;

    my @errors;
    my $ret = {};

    while ( my $opt = shift @opts ) {
        $ret->{$opt} = $c->req->body_data->{$opt};

        if ( ref($opts[0]) eq 'ARRAY'  ) {
            my $tests = shift @opts;
            while ( my $test = shift @$tests ) {

                if ( $test eq 'defined' ) {
                    push @errors, "JSON argument for $opt must be supplied."
                        unless defined($ret->{$opt});
                }

                if ( $test eq 'isTimeZone' ) {
                    push @errors, "JSON argument for $opt must be a valid timezone."
                        unless defined($ret->{$opt}) and DateTime::TimeZone->new( name => $ret->{$opt} );
                }

                if ( $test eq 'number' ) {
                    push @errors, "JSON argument for $opt must be a number."
                        unless defined($ret->{$opt}) and looks_like_number($ret->{$opt});
                }

                if ( $test =~ /^minlength=(\d+)$/ ) {
                    my $length = $1;

                    push @errors, "Length for $opt must be greater than or equal to $length"
                        unless defined($ret->{$opt}) and length($ret->{$opt}) >= $length;
                }

                if ( $test =~ /^maxlength=(\d+)$/ ) {
                    my $length = $1;

                    push @errors, "Length for $opt must be less than or equal to $length"
                        unless defined($ret->{$opt}) and length($ret->{$opt}) <= $length;
                }

                if ( $test =~ /^gte=(\d+)$/ ) {
                    my $size = $1;

                    push @errors, "Size for $opt must be greater than or equal to $size"
                        unless defined($ret->{$opt}) and $ret->{$opt} >= $size;
                }

                if ( $test =~ /^gt=(\d+)$/ ) {
                    my $size = $1;

                    push @errors, "Size for $opt must be greater than $size"
                        unless defined($ret->{$opt}) and $ret->{$opt} > $size;
                }

                if ( $test =~ /^lte=(\d+)$/ ) {
                    my $size = $1;

                    push @errors, "Size for $opt must be less than or equal to $size"
                        unless defined($ret->{$opt}) and $ret->{$opt} <= $size;
                }

                if ( $test =~ /^lt=(\d+)$/ ) {
                    my $size = $1;

                    push @errors, "Size for $opt must be less than or equal to $size"
                        unless defined($ret->{$opt}) and $ret->{$opt} < $size;
                }

                # [ foo => [ sub { looks_like_num($_) or die "Error: foo must be a number.\n" } ]
                if ( ref $test eq 'CODE' ) {
                    try { 
                        local $_ = $ret->{$opt};
                        $test->() 
                    } catch {  
                        chomp $_;
                        push @errors, "$_";
                    }; 
                }
            }
        }
    }

    if ( @errors ) {
        $c->detach( '/api/v1/error', [ { errors => \@errors } ] );
    }

    return $ret;
}

1;
