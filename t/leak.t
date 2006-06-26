#!/sw/bin/perl -w

use strict;
use YAML::Syck;
use Test::More tests => 9;

SKIP: {
    eval { require Devel::Leak }
      or skip( "Devel::Leak not installed", 9 );

    # check if arrays leak

    my $yaml = q{---
blah
};

    require Symbol;
    my $handle = Symbol::gensym();
    my $diff;

    # For some reason we have to do a full test run of this loop and the
    # Devel::Leak test before it's stable.  The first time diff ends up
    # being -2.  This is probably Devel::Leak wonkiness.
    my $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - array" );

    # Check if hashess leak
    $yaml = q{---
result: test
};

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - hash" );

	
    # Check if subs leak
	$YAML::Syck::UseCode = 1;
    $yaml = q#---
result: !perl/code: '{ 42 + $_[0] }'
#;

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - code" );


    $yaml   = q{---
a: b
c:
 - d
 - e
!
};

    ok( !eval { Load($yaml) }, "Load failed (expected)" );

    $before = Devel::Leak::NoteSV($handle);
    eval { Load($yaml) } for (1..10);
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Load failure" );

    my $todump = {a => [{c => {nums => ['1','2','3','4','5']},b => 'foo'}],d => 'e'};

    ok( eval { Dump($todump) }, "Dump succeeded" );

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
       Dump($todump);
    }
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Dump" );


    $todump = sub { 42 };

    ok( eval { Dump($todump) }, "Dump succeeded" );

    # For some reason we have to do a full test run of this loop and the
    # Devel::Leak test before it's stable.  The first time diff ends up
    # being -1.  This is probably Devel::Leak wonkiness.
	foreach ( 1 .. 100 ) {
       Dump($todump);
    }

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
       Dump($todump);
    }
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Dump code" );
}
