#!/usr/bin/env perl
use GreeHost::Spot::Test;

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

test_api( "Create an SSL Certificate.",
    [ POST => '/api/v1/sslstore', {
        name        => 'greehost.com',
        domains     => [qw( *.greehost.com *.mn.greehost.com ) ],
        provider    => 'linode',
        credentials => {
            linode_version => '4',
            linode_api_key => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        },
    }], [
        [ status_is => 200 ],
        [ json_is   => { status => 1 } ],
    ]
);

test_api( "List created SSL Certificate.",
    [ GET => '/api/v1/sslstore' ], [
        [ status_is => 200 ],
        [ json_is   => { 
            status => 1,
            store => { 
                'greehost.com' => { 
                    domains  => [ qw( *.greehost.com *.mn.greehost.com ) ], 
                    provider => 'linode', 
                    name     => 'greehost.com' 
                },
            },
        },
        ],
    ],
);


done_testing();
