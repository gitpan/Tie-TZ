#!/usr/bin/perl

# Copyright 2007, 2008 Kevin Ryde

# This file is part of Tie-TZ.
#
# Tie-TZ is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./speed.pl
#
# Measure the relative speeds of Tie::TZ and DateTime::TimeZone.
#
# For me DateTime is about 3.5 times faster in a hard loop like this.  One
# of the worst things about glibc is that it re-reads a /usr/share/zoneinfo/
# file on every change.  Probably that's not too bad for the normal case of
# relatively few zone changes in a program, but if you're going around the
# world it makes DateTime a much more likely proposition.
#

use strict;
use warnings;
use List::Util qw(min max);
use POSIX ();
use Time::HiRes;

use Tie::TZ;
use DateTime;
use DateTime::TimeZone;

use constant TARGET_DURATION => 2; # seconds

sub speed {
  my ($subr) = @_;
  my $t = 0;
  my $runs = 1;

  &$subr(); # warmup

  for (;;) {
    print "  $runs runs";
    my $s = Time::HiRes::time();
    foreach (1 .. $runs) {
      &$subr();
    }
    my $e = Time::HiRes::time();
    $t = $e - $s;
    my $each = $t/$runs;
    my $ms = $each * 1000.0;
    printf " took %.6f, is %.3f milliseconds each\n", $t, $ms;

    if ($t > TARGET_DURATION) {
      last;
    }
    if ($t == 0) {
      $runs *= 5;
    } else {
      $runs = max ($runs * 2, POSIX::ceil((TARGET_DURATION + 1) / $t));
    }
  }
  return $t / $runs;
}

# about 1.13ms each
print "Tie::TZ\n";
my $tz = 'Europe/London';
my $tie_tz_each = speed (sub { local $Tie::TZ::TZ = $tz; return 0; });

# about 0.36ms each
print "DateTime::TimeZone\n";
$tz = DateTime::TimeZone->new (name => 'Europe/London');
my $dt = DateTime->now();
my $datetime_each = speed (sub { $tz->offset_for_datetime($dt) });

if ($tie_tz_each > $datetime_each) {
  printf "DateTime is %.2f times faster\n", $tie_tz_each / $datetime_each;
} else {
  printf "TZ is %.2f times faster\n", $datetime_each / $tie_tz_each;
}


use Benchmark ':hireswallclock';
my $bench = {'Tie::TZ' => sub { local $Tie::TZ::TZ = $tz; return 0; },
             'DateTime::TimeZone' => sub { $tz->offset_for_datetime($dt) },
            };
Benchmark::timethese (-5, $bench);
Benchmark::cmpthese (-5, $bench);


exit 0;
