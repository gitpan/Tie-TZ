# Copyright 2007, 2008 Kevin Ryde

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

package Tie::TZ;
use strict;
use warnings;
use Exporter;

use vars qw(@ISA @EXPORT_OK $TZ $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw($TZ);
tie $TZ, __PACKAGE__;

$VERSION = 2;

use constant DEBUG => 0;

sub TIESCALAR {
  my ($class) = @_;
  my $self = __PACKAGE__.' oops, magic not used!';
  return bless \$self, $class;
}

sub FETCH {
  if (DEBUG >= 2) { print "TiedTZ fetch ",
                      (defined $ENV{'TZ'} ? $ENV{'TZ'} : 'undef'),"\n"; }
  return $ENV{'TZ'};
}

sub STORE {
  my ($self, $newval) = @_;
  if (DEBUG) { print "TiedTZ store ",
                 (defined $newval ? $newval : 'undef'),"\n"; }

  my $oldval = $ENV{'TZ'};
  if (defined $newval) {
    if (defined $oldval && $oldval eq $newval) {
      if (DEBUG) { print "  unchanged: $oldval\n"; }
      return;
    }
    $ENV{'TZ'} = $newval;

  } else {
    if (! defined $oldval) {
      if (DEBUG) { print "  unchanged: undef\n"; }
      return;
    }
    delete $ENV{'TZ'};
  }

  if (DEBUG) { print "  tzset()\n"; }
  require POSIX;
  POSIX::tzset();
}

1;
__END__

=head1 NAME

Tie::TZ - tied $TZ setting %ENV and calling tzset()

=head1 SYNOPSIS

 use Tie::TZ qw($TZ);
 $TZ = 'GMT';

 { local $TZ = 'EST+10';
   ...
 }

=head1 DESCRIPTION

This module provides a tied C<$TZ> variable which gets and sets
C<$ENV{'TZ'}>.  When it sets C<%ENV> it calls C<POSIX::tzset()>, ensuring
the C library notices the change for subsequent C<localtime>, etc.

    $TZ = 'GMT';
    # does  $ENV{'TZ'} = 'GMT';  POSIX::tzset();

For a plain set you can just as easily store and C<tzset> yourself (or have
a function to do the combo).  The power of a tied variable comes when using
C<local> to have a different timezone temporarily.  Any C<goto>, C<return>,
C<die>, etc, exiting the block will restore the old setting, including a
C<tzset> for it.

    { local $TZ = 'GMT';
      print ctime();
      # TZ restored at block exit
    }

    { local $TZ = 'GMT';
      die 'Something';
      # TZ restored when the die unwinds
    }

Storing C<undef> to C<$TZ> deletes C<$ENV{'TZ'}>, unsetting the environment
variable.  This generally means the timezone goes back to the system default
local time (usually per from F</etc/timezone>).

As an optimization, if a store to C<$TZ> is already what C<$ENV{'TZ'}>
contains then C<tzset> is not called.  This is helpful if some of the
settings you're working are all the same.  If there's never any different
value applied then C<POSIX> module is not even loaded at all.

=head2 Uses

Quite often C<tzset> is not actually needed.  Decent C libraries look for a
new TZ each time in the various C<localtime> etc functions.  But C<tzset>
keeps you out of trouble on older systems, or with any external libraries
directly accessing the C global variables like C<timezone> or C<daylight>.

Perl's own calls to C<localtime> etc do a C<tzset> themselves where
necessary to cope with old C libraries (based on a configure test, see
L<Config>).  However in 5.8.8 and earlier Perl didn't do that on
C<localtime_r>, and the latter in some versions of GNU C can need an
explicit C<tzset>; the net result being that you need C<tzset> in threaded
Perl 5.8.8 (whether using threads or not).  Of course even when Perl
recognises C library limitations you might not be so lucky deep in external
libraries.

=head1 EXPORTS

By default nothing is exported and you can use the full name
C<$Tie::TZ::TZ>,

    use Tie::TZ;
    $Tie::TZ::TZ = 'GMT';

Or import C<$TZ> in the usual way (see L<Exporter>) as a shorthand

    use Tie::TZ '$TZ';
    $TZ = 'GMT';

=head1 OTHER NOTES

The C<local> trick above of course works with C<$ENV{'TZ'}> directly too if
you're happy that you don't need C<tzset>, eg. C<< local $ENV{'TZ'} =
'EST+10' >>.  The C<Env> module can let you tie a C<$TZ> name for that too
if desired.  However C<undef> ends up meaning an empty string instead of
unset, which may be subtly different, and it also provokes a warning from
Perl prior to 5.10.

When you get sick of the C library timezone handling have a look at
L<DateTime::TimeZone>.  Its data tables make it big (though no doubt you
could turf what you don't use) but it's all Perl and is much friendlier if
you're working in multiple zones more or less simultaneously.

=head1 SEE ALSO

L<POSIX>, L<Env>, L<DateTime::TimeZone>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/tie-tz/index.html>

=head1 COPYRIGHT

Copyright 2008 Kevin Ryde

Tie-TZ is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Tie-TZ.  If not, see L<http://www.gnu.org/licenses>.

=cut
