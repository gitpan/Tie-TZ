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

package Time::TZ;
use strict;
use warnings;
use Carp;
use Tie::TZ;
use vars qw($VERSION);

$VERSION = 6;

use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;
  my $self = bless \%self, $class;
  unless (delete $self{'defer'}) {
    $self->tz;
  }
  return $self;
}

sub name {
  my ($self) = @_;
  return $self->{'name'};
}

sub tz {
  my ($self) = @_;
  if (my $choose = delete $self->{'choose'}) {
    foreach my $tz (@$choose) {
      if ($self->tz_known($tz)) {
        if (DEBUG) { print "Time::TZ choose $tz\n"; }
        return ($self->{'tz'} = $tz);
      }
    }
    my $name = $self->name;
    my $msg = "TZ" . (defined $name ? " '$name'" : '')
      . ': no zone known to the system among: '
        . join(' ',@$choose);
    if (defined (my $tz = delete $self->{'fallback'})) {
      warn $msg,", using $tz instead\n";
      return ($self->{'tz'} = $tz);
    }
    croak $msg;
  }
  return $self->{'tz'};
}

sub tz_known {
  my ($class_or_self, $tz) = @_;
  if (! defined $tz || $tz eq 'UTC' || $tz eq 'GMT') { return 1; }

  # any hour or minute different from GMT in any of 12 calendar months
  my $timet = time();
  local $Tie::TZ::TZ = $tz;
  foreach my $mon (1 .. 12) {
    my $delta = $mon * 30 * 86400;
    my $t = $timet + $delta;
    my ($l_sec,$l_min,$l_hour,$l_mday,$l_mon,$l_year,$l_wday,$l_yday,$l_isdst)
      = localtime ($t);
    my ($g_sec,$g_min,$g_hour,$g_mday,$g_mon,$g_year,$g_wday,$g_yday,$g_isdst)
      = gmtime ($t);
    if ($l_hour != $g_hour || $l_min != $g_min) {
      return 1;
    }
  }
  return 0;
}

sub localtime {
  my ($self, $timet) = @_;
  if (! defined $timet) { $timet = time(); }
  local $Tie::TZ::TZ = $self->tz;
  return localtime ($timet);
}

sub call {
  my $self = shift;
  my $subr = shift;
  local $Tie::TZ::TZ = $self->tz;
  return $subr->(@_);
}

1;
__END__

=head1 NAME

Time::TZ -- object-oriented TZ settings

=for test_synopsis my ($auck, $frank, @parts, $timet)

=head1 SYNOPSIS

 use Time::TZ;
 $auck = Time::TZ->new (tz => 'Pacific/Auckland');

 $frank = Time::TZ->new (name     => 'Frankfurt',
                         choose   => [ 'Europe/Frankfurt',
                                       'Europe/Berlin' ],
                         fallback => 'CET-1CEDT,M3.5.0,M10.5.0/3');

 @parts = $auck->localtime($timet);

=head1 DESCRIPTION

This is an object-oriented approach to C<TZ> environment variable settings,
ie. C<$ENV{'TZ'}>.  A C<Time::TZ> object holds a TZ string and has methods
to make calculations in that zone by temporarily changing the C<TZ>
environment variable (see L<Tie::TZ>).

The advantage of this approach is that it needs only a modest amount of code
and uses the same system timezones as other programs.  Of course whether the
system timezones are up-to-date etc is another matter, and switching C<TZ>
for each calculation can be disappointingly slow (for example in the GNU C
Library).

=head1 FUNCTIONS

=over 4

=item C<< $tz = Time::TZ->new (key=>value, ...) >>

Create and return a new TZ object.  The possible key/value parameters are

    tz        TZ string
    choose    arrayref of TZ strings
    fallback  TZ string
    name      free-form name string

If C<choose> is given then the each TZ string in the array is checked and
the first known to the system is used (see C<tz_known> below).  C<choose> is
good if a place has different settings on different systems or new enough
systems.

    my $brem = Time::TZ->new (choose => [ 'Europe/Bremen',
                                          'Europe/Berlin' ]);

If none of the C<choose> settings are known then C<new> croaks.  If you
supply a C<fallback> then it just carps and uses that fallback value.

    my $brem = Time::TZ->new (choose => [ 'Europe/Bremen',
                                          'Europe/Berlin' ],
                              fallback => 'CET-1');

The C<name> parameter is not used for any timezone calculations, it's just a
handy way to keep a human-readable placename with the object.

=item C<bool = Time::TZ-E<gt>tz_known ($str)>

Return true if C<TZ> setting C<$str> is known to the system (the C library
etc).

    $bool = Time::TZ->tz_known ('EST+10');          # true
    $bool = Time::TZ->tz_known ('some bogosity');   # false

In the GNU C Library, a bad C<TZ> setting makes C<localtime> come out as
GMT, so the test is that C<$str> gives C<localtime> different from C<gmtime>
on one of a range of values through the year (so it can be the same as GMT
during daylight savings, or non daylight savings).  Zones "GMT" and "UTC"
are always considered known.

Comparing against GMT is no good for places like "Africa/Accra" which are
known but are just GMT.  The suggestion is not to use C<choose> but just put
it in unconditionally,

    my $acc = Time::TZ->new (tz => 'Africa/Accra');

=back

=head2 Object Methods

=over 4

=item C<$str = $tz-E<gt>tz()>

Return the C<TZ> string of C<$tz>.

=item C<$str = $tz-E<gt>name()>

Return the name of C<$tz>, or C<undef> if none set.

=back

=head2 Time Operations

=over 4

=item C<ret = $tz-E<gt>call ($subr)>

=item C<ret = $tz-E<gt>call ($subr, $arg, ...)>

Call C<$subr> with the C<TZ> environment variable temporarily set to
C<$tz-E<gt>tz>.  The return value is the return from C<$subr>, with the same
scalar or array context as the C<call> method itself.

    $tz->call (sub { print "the time is ",ctime() });

    my $year = $tz->call (\&Date::Calc::This_Year);

Arguments are passed on to C<$subr>.  For an anonymous sub there's no need
for such arguments, but they can be good for a named sub,

    my @ret = $tz->call (\&foo, 1, 2, 3);

=item C<@lt = $tz-E<gt>localtime ()>

=item C<@lt = $tz-E<gt>localtime ($time_t)>

Call C<localtime> (see L<perlfunc/localtime>) in the given C<$tz> timezone.
C<$time_t> is a value from C<time()>, or defaults to the current C<time()>.
The return is the usual list of 9 localtime values.

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
          = $tz->localtime;

=back

=head1 SEE ALSO

L<Tie::TZ>, L<perlvar/ENV>, L<Time::localtime>, L<DateTime::TimeZone>

=head1 HOME PAGE

http://user42.tuxfamily.org/tie-tz/index.html

=head1 COPYRIGHT

Copyright 2007, 2008, 2009 Kevin Ryde

Tie-TZ is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Tie-TZ.  If not, see <http://www.gnu.org/licenses/>.

=cut
