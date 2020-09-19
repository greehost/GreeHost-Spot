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

test_api( "Create a Project",
    [ POST => '/api/v1/project', {
        name        => 'greehost.org',
        description => 'GreeHost Documentation Website',
        repository  => 'git@github.com/greehost/greehost.org.git',
        ssh_key     => 'ssh-rsa aaaa.....', 
    }], [
        [ status_is => 200 ],
        [ json_is   => { status => 1 } ],
    ]
);

test_api( "List created Project",
    [ GET => '/api/v1/project' ], [
        [ status_is => 200 ],
        [ json_is   => { 
            status => 1,
            project => { 
                'greehost.org' => { 
                    name        => 'greehost.org',
                    description => 'GreeHost Documentation Website',
                    repository  => 'git@github.com/greehost/greehost.org.git',
                },
            },
        },
        ],
    ],
);

done_testing;
