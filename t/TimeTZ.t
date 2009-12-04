#!/usr/bin/perl

# Copyright 2007, 2008, 2009 Kevin Ryde

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
use Time::TZ;

use Test::More tests => 12;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

#------------------------------------------------------------------------------
# name()

{
  my $tz = Time::TZ->new (name => 'Greenwich Mean Time',
                          tz => 'GMT');
  is ($tz->name, 'Greenwich Mean Time', 'GMT name');
}


#------------------------------------------------------------------------------
# choose

{
  my $tz = Time::TZ->new (choose => [ 'some bogosity', 'GMT' ]);
  is ($tz->tz, 'GMT', 'choose not some bogosity');
}
{
  my $tz = Time::TZ->new (choose => [ 'EST-10', 'GMT' ]);
  is ($tz->tz, 'EST-10', 'choose EST-10');
}


#------------------------------------------------------------------------------
# call()

{
  local $ENV{'TZ'} = 'BST+1';
  my $tz = Time::TZ->new (name => 'test GMT',
                          tz => 'GMT');

  $tz->call (sub { is ($ENV{'TZ'}, 'GMT'); });
  is ($ENV{'TZ'}, 'BST+1', "restored after normal return");

  ## no critic (RequireCheckingReturnValueOfEval)
  eval {
    $tz->call (sub {
                 is ($ENV{'TZ'}, 'GMT');
                 die "foo";
               });
  };
  is ($ENV{'TZ'}, 'BST+1', "restored after die");
}

#------------------------------------------------------------------------------
# tz_known()

ok (Time::TZ->tz_known('GMT'));
ok (Time::TZ->tz_known('UTC'));
ok (! Time::TZ->tz_known('some bogosity'));
ok (Time::TZ->tz_known('EST+10'));

exit 0;
