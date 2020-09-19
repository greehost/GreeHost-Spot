package GreeHost::Spot::Test;
use warnings;
use strict;
use Test::More;
use Test::Deep;
use Test::Postgresql58;
use Try::Tiny;
use JSON::MaybeXS;
use Catalyst::Test ();
use HTTP::Request;
use HTTP::Cookies;
use Import::Into;
use Exporter;
use Data::Dumper;
use DateTime;
use Object::Tap;
use URI;
use IPC::Run3;
push our @ISA, qw( Exporter );
push our @EXPORT, qw( set_date test_api test_api_requests );

## TODO: At some point look at Test2 Suite / Test2 API

my $heap = {};

sub import {
    shift->export_to_level(1);
    my $target = caller;
    warnings->import::into($target);
    strict->import::into($target);
    Test::More->import::into($target);
    Test::Deep->import::into($target);
}

our $pgsql = Test::Postgresql58->new()
    or BAILOUT( "PSQL Error: " .  $Test::Postgresql58::errstr );

$ENV{IS_RUNNING_TESTS} = 1;
$ENV{PSQL_TEST_DB_DSN}  = $pgsql->dsn;

load_psql_file( '/opt/catalyst/schema.sql' );

Catalyst::Test->import('GreeHost::Spot');

sub _structure_request {
    my ( $request ) = @_;

    return {
        type    => $request->[0],
        url     => $request->[1],
        data    => { %{$request->[2] || {} } },
        headers => { %{$request->[3] || {} } },
        coderef => $request->[4],
    };
}

sub test_api {
    my ( $name, $request, $expects, $returns ) = @_;
    my ( undef, $file, $line ) = caller;
    
    $request = _structure_request( $request );
    
    if ( $request->{coderef} and ref $request->{coderef} eq 'CODE' ) {
        $request = $request->{coderef}->($request, $heap);
    }

    my $function = __PACKAGE__->can( "_make_${\(lc $request->{type})}_request" )
        or BAIL_OUT( sprintf("Invalid request type: %s, called at %s:%d", $request->{type}, $file, $line ));
    
    my ( $res, $c ) = $function->($request->{url}, $request->{data}, $request->{headers});

    foreach my $expect ( @$expects ) {
        my $test_method_name = shift @$expect;

        my $test_code = __PACKAGE__->can( "_test_run_$test_method_name" )
            or die "Invalid test function: $test_method_name @ $file:$line";

        $test_code->($res, $c, $file, $line, @$expect );

    }

    return $returns->( $res, $c, $heap )
        if $returns and ref $returns eq 'CODE';
    return $heap;
};

sub _test_run_status_is {
    my ( $res, $c, $file, $line, $status_code ) = @_;

    is $res->code, $status_code, 
        sprintf("%s:%d: Correct HTTP Status Code", $file, $line);
}

sub _test_run_json_has {
    my ( $res, $c, $file, $line, $json ) = @_;

    print STDERR "Running right code block...\n";
    cmp_deeply _get_json($res), superhashof($json), 
        sprintf("%s:%d: Response has correct JSON values.", $file, $line);
}

sub _test_run_dump_json {
    my ( $res, $c, $file, $line ) = @_;

    print STDERR Dumper( _get_json($res) );
}

sub _test_run_json_is {
    my ( $res, $c, $file, $line, $json ) = @_;

    cmp_deeply _get_json($res), $json, 
        sprintf("%s:%d: Response has correct JSON values.", $file, $line);
}

sub _test_run_header_is {
    my ( $res, $c, $file, $line, $header_key, $header_value ) = @_;

    ok $res->header($header_key), 
        sprintf( "%s:%d: Header %s exists.", $file, $line, $header_key );

    is $res->header($header_key), $header_value, 
        sprintf( "%s:%d Header %s has expected value", $file, $line, $header_key )
}

sub _test_run_header_like {
    my ( $res, $c, $file, $line, $header_key, $header_value ) = @_;

    ok $res->header($header_key), 
        sprintf( "%s:%d: Header %s exists.", $file, $line, $header_key );

    like $res->header($header_key), $header_value, 
        sprintf( "%s:%d Header %s has expected value", $file, $line, $header_key )
}

sub _test_run_code {
    my ( $res, $c, $file, $line, $code ) = @_;
    
    $code->( $res, $c, $file, $line, $heap );
}

sub _test_run_psql_prompt {
    my ( $res, $c, $file, $line, $code ) = @_;

    my $uri = URI->new( $pgsql->uri );

    # This command should only be invoked when running with perl, because prove does fucked up things to
    # stderr/stdout and I have been unable to figure out how to make it work 100% correctly with file handles
    # from this code.
    if ( $ENV{HARNESS_ACTIVE} and $ENV{HARNESS_ACTIVE} == 1 ) {
        print STDERR "\033[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\033[0m\n";
        print STDERR "\033[31mERROR: psql_prompt does not work correctly under prove.  Please run with perl\033[0m\n";
        print STDERR "\033[31m!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\033[0m\n";
        BAIL_OUT( "Do not use psql_prompt from within prove.  Use perl instead." );
    }
    run3 [ 'psql', '-U', $uri->user, '-h', $uri->host, '-p', $uri->port, $uri->dbname ];
}

sub _test_run_dump_res {
    my ( $res, $c, $file, $line ) = @_;

    print STDERR Dumper($res);
}

# Helper Functions

sub _get_json {
    my ( $response ) = @_;

    return try {
        decode_json( $response->decoded_content );
    } catch {
        BAIL_OUT("Failed to decode JSON: $_");
    };  
}

{
    my $cookie_jar;

    sub set_cookies_from_response {
        my ( $res ) = @_;
        $cookie_jar = HTTP::Cookies->new unless $cookie_jar;
        $cookie_jar->extract_cookies($res);
    }

    sub set_cookies_on_request {
        my ( $req ) = @_;

        return $req unless $cookie_jar;
        return $cookie_jar->add_cookie_header($req);
    }

    sub clear_cookies {
        undef $cookie_jar;
    }
}

sub load_psql_file {
    my ( $file ) = @_;
    
    open my $lf, "<", $file
        or die "Failed to open $file for reading: $!";
    my $content;
    while ( defined( my $line = <$lf> ) ) {
        next unless $line !~ /^\s*--/;
        $content .= $line;
    }
    close $lf;

    my $dbh = DBI->connect( $pgsql->dsn );
    for my $command ( split( /;/, $content ) ) {
        next if $command =~ /^\s*$/;
        $dbh->do( $command )
            or BAIL_OUT( "PSQL Error($file): $command: " . $dbh->errstr);
    }
    undef $dbh;
}



# HTTP Transaction Functions

sub _make_post_like_request {
    my ( $method, $url, $data, $headers ) = @_;

    my $req = HTTP::Request->new( $method => 'http://localhost.local' . $url )
        ->$_tap(header => content_type => 'application/json', %{$headers || {}} )
        ->$_tap(content => encode_json($data));

    $req = set_cookies_on_request($req);

    my ($res, $c) = ctx_request( $req );
    
    set_cookies_from_response($res);

    ok( $res, "HTTP POST $url successful." );

    return ( $res, $c );
}

sub _make_get_like_request {
    my ( $method, $url, $data, $headers ) = @_;

    my $req = HTTP::Request->new(
        $method => URI->new( 'http://localhost.local' . $url)->$_tap(query_form => $data)
    )->$_tap(header => accept => 'application/json', %{$headers || {}});

    $req = set_cookies_on_request($req);

    my ($res, $c) = ctx_request( $req );
    
    set_cookies_from_response($res);

    ok( $res, "HTTP GET $url successful." );

    return ( $res, $c );
}

sub _make_post_request { 
    _make_post_like_request( 'POST', @_ ); 
}

sub _make_put_request { 
    _make_post_like_request( 'PUT', @_ ); 
}

sub _make_get_request {
    _make_get_like_request( 'GET', @_ );
}

sub _make_delete_request {
    _make_get_like_request( 'DELETE', @_ );
}

1;

