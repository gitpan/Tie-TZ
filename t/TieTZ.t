#!/usr/bin/perl

# Copyright 2008 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Tie::TZ;
use Test::More tests => 45;

ok ($Tie::TZ::VERSION >= 1);
ok (Tie::TZ->VERSION  >= 1);


diag ('delete ENV');
{ delete $ENV{'TZ'};
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, undef);
  is ($got, undef);
  is ($Tie::TZ::TZ, undef);
}

diag ('ENV = GMT');
{ $ENV{'TZ'} = 'GMT';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'GMT');
  is ($got, 'GMT');
  is ($Tie::TZ::TZ, 'GMT');
}

diag ('ENV = undef');
{ $ENV{'TZ'} = undef;
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, undef);
  is ($got, undef);
  is ($Tie::TZ::TZ, undef);
}

diag ('TZ = UTC');
{ $Tie::TZ::TZ = 'UTC';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}

diag ('TZ = GMT');
{ $Tie::TZ::TZ = 'GMT';
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'GMT');
  is ($got, 'GMT');
  is ($Tie::TZ::TZ, 'GMT');
}

diag ('TZ = undef');
{ $Tie::TZ::TZ = undef;
  my $got = $Tie::TZ::TZ;
  ok (! exists $ENV{'TZ'});
  is ($got, undef);
  is ($Tie::TZ::TZ, undef);
}

diag ('ENV = UTC, local TZ = GMT, local TZ = EST');
$ENV{'TZ'} = 'UTC';
{ { local $Tie::TZ::TZ = 'GMT';
    my $got = $Tie::TZ::TZ;
    is ($ENV{'TZ'}, 'GMT');
    is ($got, 'GMT');
    is ($Tie::TZ::TZ, 'GMT');

    { local $Tie::TZ::TZ = 'EST+10';
      my $got = $Tie::TZ::TZ;
      is ($ENV{'TZ'}, 'EST+10');
      is ($got, 'EST+10');
      is ($Tie::TZ::TZ, 'EST+10');
    }

    $got = $Tie::TZ::TZ;
    is ($ENV{'TZ'}, 'GMT');
    is ($got, 'GMT');
    is ($Tie::TZ::TZ, 'GMT');
  }
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}

diag ('ENV = UTC, local TZ = GMT, with die out of eval');
{ $ENV{'TZ'} = 'UTC';
  eval { local $Tie::TZ::TZ = 'GMT';
         my $got = $Tie::TZ::TZ;
         is ($ENV{'TZ'}, 'GMT');
         is ($got, 'GMT');
         is ($Tie::TZ::TZ, 'GMT');
         die; };
  my $got = $Tie::TZ::TZ;
  is ($ENV{'TZ'}, 'UTC');
  is ($got, 'UTC');
  is ($Tie::TZ::TZ, 'UTC');
}


{ my $saw_tzset = 0;
  no warnings;
  local *POSIX::tzset = sub {
    $saw_tzset = 1;
  };
  use warnings;

  $ENV{'TZ'} = 'UTC';
  { $saw_tzset = 0;
    $Tie::TZ::TZ = 'UTC';
    is ($saw_tzset, 0, 'UTC -> UTC');
  }
  { $saw_tzset = 0;
    $Tie::TZ::TZ = 'GMT';
    is ($saw_tzset, 1, 'UTC -> GMT');
  }
  { $saw_tzset = 0;
    $Tie::TZ::TZ = undef;
    is ($saw_tzset, 1, 'GMT -> undef');
  }
  { $saw_tzset = 0;
    $Tie::TZ::TZ = undef;
    is ($saw_tzset, 0, 'undef -> undef');
  }
  { $saw_tzset = 0;
    $Tie::TZ::TZ = 'UTC';
    is ($saw_tzset, 1, 'undef -> UTC');
  }
}

# Return true if setting $ENV{'TZ'} does indeed affect what localtime()
# returns.  As noted in the "perlport" pod, on some systems TZ might have no
# effect at all.
#
sub tz_affects_localtime {
  require POSIX;
  $ENV{'TZ'} = 'GMT';
  POSIX::tzset();
  my (undef, undef, $gmt_hour) = localtime (0);

  $ENV{'TZ'} = 'BST+1';
  POSIX::tzset();
  my (undef, undef, $bst_hour) = localtime (0);

  return ($gmt_hour != $bst_hour);
}

# check that a mere "local $ENV{TZ}" affects localtime, since that's all we
# do in the code; though 
{
 SKIP: {
    if (! tz_affects_localtime()) {
      skip 'due to TZ variable having no effect', 2;
    }

    # assuming localtime() is indeed influenced, see that for example BST+1
    # is an hour behind GMT
    #
    $Tie::TZ::TZ = 'GMT';
    my (undef, undef, $gmt_hour) = localtime (0);
    my $bst_hour;
    { local $ENV{'TZ'} = 'BST+1';
      (undef, undef, $bst_hour) = localtime (0);
      is ($bst_hour, ($gmt_hour - 1 + 24) % 24,
          'BST+1 within local Tie::TZ setting');
    }
    my (undef, undef, $gmt_again_hour) = localtime (0);
    is ($gmt_again_hour, $gmt_hour,
        'GMT hour before and after local Tie::TZ setting');

  }
  POSIX::tzset();
}

exit 0;
