#!/usr/bin/env perl
use GreeHost::Spot::Test;

=head1 Test Description

This test verifies that a user account can be created, and once created the 
user can login.  Verification of the user account is further confirmed by 
verifying the user listing at /user/~ work.

=cut

my $uid = test_api ( "Create user account",
    [ POST => '/api/v1/user', 
        { 
            name => 'Test User',
            email => 'test@todaychecklist.com',
            password => 'userpassword',
        },
    ], 
    [
        [ status_is => 200 ],
        [ json_has => { status => 1 } ],
    ],
    sub {
        my ( $res, $c, $heap ) = @_;
        return $c->stash->{json}->{person}->{uid};
    },
);

test_api( "Login to the user account",
    [ POST => '/api/v1/auth/login', 
        { 
            email => 'test@todaychecklist.com',
            password => 'userpassword',
        },
    ], [
        [ status_is => 200 ],
        [ json_has => { status => 1 } ],
    ],
);

test_api( "Verify that cookies work to get account information",
    [ GET => '/api/v1/user/~/' ], 
    [
        [ status_is => 200 ],
        [ json_is  => { 
                status => 1,
                person => { 
                    name => 'Test User', 
                    email => 'test@todaychecklist.com', 
                    uid   => $uid,
                },
            } 
        ],
    ]
);

done_testing();
