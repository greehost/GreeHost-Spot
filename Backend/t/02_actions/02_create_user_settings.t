#!/usr/bin/env perl
use GreeHost::Spot::Test;

=head1 Test Description

This test verifies that settings can be associated with a user account based
on the use of the /user/~/settings API endpoints.

Testing protocol:

    1. Create a user account & login for session cookie
    2. Submit multiple settings
    3. Verify that /user/~/settings returns { settings => _ALL_SETTINGS_ }
    4. Verify that /users/~/settings?name returns { name => _SETTING_ } 
       and multiple name fields function correctly.
    5. Verify a setting can be changed via the same mechanism that created
       it.
    6. Verify that unknown user settings being looked up returns an error.

=cut

test_api ( "Create user account",
    [ POST => '/api/v1/user', 
        { 
            name => 'Test User',
            email => 'test@todaychecklist.com',
            password => 'userpassword',
        },
    ], 
);

test_api( "Login to the user account",
    [ POST => '/api/v1/auth/login', 
        { 
            email => 'test@todaychecklist.com',
            password => 'userpassword',
        },
    ],
);

test_api("Create settings",
    [ POST => '/api/v1/user/~/settings',
        { settings => {
            simple_value           => 'Hello World',
            complex_value_hashref  => { foo => 'bar', blee => 'baz'},
            complex_value_arrayref => [qw( a b c d )],
        }},
    ], [
        [ status_is => 200 ],
        [ json_is   => { status => 1 } ],
    ]
);

test_api(  "Get All Values",
    [ GET => '/api/v1/user/~/settings' ],
    [
        [ json_is => {
            status => 1,
            settings => superhashof({
                simple_value => 'Hello World',
                complex_value_hashref => {
                    foo => 'bar',
                    blee => 'baz',
                },
                complex_value_arrayref => [ qw( a b c d )],
            }),
        }],
    ],
);

test_api(  "Get One Simple Value",
    [ GET => '/api/v1/user/~/settings', 
        { name => 'simple_value' },
    ], [
        [ json_has => { simple_value => 'Hello World' } ],
    ],
);

test_api(  "Get One Complex Value Hash",
    [ GET => '/api/v1/user/~/settings',
        { name => 'complex_value_hashref' },
    ], [
        [ json_has => { complex_value_hashref => { foo => 'bar', blee => 'baz' } } ],
    ],
);

test_api(  "Get One Complex Value Array",
    [ GET => '/api/v1/user/~/settings',
        { name => 'complex_value_arrayref' },
    ], [
        [ json_has => { complex_value_arrayref => [ qw( a b c d ) ] } ],
    ],
);

test_api(  "Get One Complex Value Array",
    [ GET => '/api/v1/user/~/settings',
        { name => [qw( complex_value_arrayref complex_value_hashref simple_value )] },
    ], [
        [ json_has => { 
            simple_value           => 'Hello World',
            complex_value_hashref  => { foo => 'bar', blee => 'baz' },
            complex_value_arrayref => [ qw( a b c d ) ],
        }],
    ],
);

test_api("Replace setting keys with new values.",
    [ POST => '/api/v1/user/~/settings',
        { settings => {
            simple_value           => 'Goodbye',
            complex_value_hashref  => { bam => 'boom' },
            complex_value_arrayref => [qw( x y z )],
        }},
    ], [
        [ status_is => 200 ],
        [ json_is   => { status => 1 } ],
    ]
);

test_api(  "Verify that the new settings took hold.",
    [ GET => '/api/v1/user/~/settings' ],
    [
        [ json_is => {
            status => 1,
            settings => superhashof({
                simple_value => 'Goodbye',
                complex_value_hashref => { bam => 'boom' },
                complex_value_arrayref => [ qw( x y z )],
            }),
        }],
    ],
);

test_api(  "Get value that does not exist.",
    [ GET => '/api/v1/user/~/settings',
        { name => 'value-that-doesnt-exist' },
    ], [
        [ status_is => 500 ],
        [ json_is   => { status => 0, error => "Unknown setting value-that-doesnt-exist" } ],
    ],
);

done_testing();
