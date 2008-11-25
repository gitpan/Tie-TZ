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

$VERSION = 1;

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

For a plain set you can just as easily store and C<tzset> yourself.  The
power comes when using C<local> to have a different timezone temporarily.
Any C<goto>, C<return>, C<die>, etc, exiting the block will restore the old
setting and do C<tzset>.

    { local $TZ = 'GMT';
      print ctime();
      # TZ restored at block exit
    }

    { local $TZ = 'GMT';
      die 'Something';
      # TZ restored when the die unwinds
    }

As an optimization, if a store to C<$TZ> is already what C<$ENV{'TZ'}>
contains then C<tzset> is not called.  This is helpful when some settings
you're working with might be all the same.  If there's never any changes
applied then C<POSIX> module is not even loaded at all.

=head2 Uses

Quite often C<tzset> is not actually needed.  Decent C libraries look for a
new TZ each time in the various C<localtime> etc.  But C<tzset> keeps you
out of trouble on older systems, or with any external libraries directly
accessing the C<tzname> and C<daylight> global variables.

Perl's own calls to C<localtime> etc do a C<tzset> themselves where
necessary (based on a configure test, see L<Config>) to cope with old C
libraries.  But Perl doesn't that on C<localtime_r> until 5.8.9 (or some
such), and the latter in fact in some versions of GNU C can need an explicit
C<tzset>; the net result being that you need C<tzset> in a threaded Perl
5.8.8 (even when not using threads).  Of course even if Perl recognises C
library limitations you might not be so lucky deep in external libraries.

=head1 EXPORTS

By default nothing is exported and you can use the full name
C<$Tie::TZ::TZ>,

    use Tie::TZ;
    $Tie::TZ::TZ = 'GMT';

Or import C<$TZ> in the usual way (see L<Exporter>) as a convenient
shorthand

    use Tie::TZ '$TZ';
    $TZ = 'GMT';

=head1 OTHER NOTES

When you get sick of the C library's fairly ordinary timezone handling have
a look at L<DateTime::TimeZone>.  Its data tables make it big, though no
doubt you can turf what you don't use.  It's all Perl and can be a lot
friendlier if you're working in multiple zones more or less simultaneously.

=head1 SEE ALSO

L<POSIX>

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
