#!/usr/bin/perl -w
# $Id: text_density,v 1.2 2003/11/29 15:16:46 comdog Exp $
use strict;

=head1 NAME

text_density - turn a text file into a density plot

=head1 DESCRIPTION

The C<text_density> program turns a text file into a density
plot. The density at a character position depends on the number
of other characters around it.  It outputs a colored PNG image
where blue represents areas of no characters and red represents
the area of highest density.  Each image holds up to 250 lines
of the text, using additional images for more lines and an HTML
text file to show all of the images.

Just for kicks, you know.

This program does not modify the source text.

=head1 TO DO

* make a second approximation - score some characters greater
than others

* specify a range of line numbers

* command line options and config file

* Text::Template for HTML output

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	https://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy E<lt>bdfoy@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003, brian d foy.  All rights reserved.

This program may be redistributed under the same turns as Perl
itself.

=cut


use File::Basename;
use GD;

my @Matrix;      # store the file in a matrix, one char per position
my @Score;       # store the positions score
my $Longest = 0; # remember the longest line.  That's the dim

use constant LINE_LENGTH      => 73;
use constant EDGE_SCORE       => 0;
use constant WHITESPACE_SCORE => 0;
use constant CHAR_SCORE       => 1;
use constant SCALE_FACTOR     => 3;
use constant PAGE_LENGTH      => 250;

open my($fh), $ARGV[0] or die "Skipping $ARGV[0]: $!\n";

while( <$fh> )
	{
	chomp;
	s/\t/    /g;
	my $length = length;
	my @line = split //;
	push @Matrix, [ @line ];
	$Longest = $length if $length > $Longest;
	}
	
my $last_line = $.; # remember the last line.  That's the rank.

foreach my $row ( 0 .. $#Matrix )
	{
	my $line = $Matrix[$row];
	
	foreach my $col ( 0 .. $#$line )
		{
		neighbors( $row, $col ) #Create the %Score matrix
		}
	}

=head1 print the results as text

foreach my $row ( 0 .. $#Matrix )
	{
	my $line = $Matrix[$row];
	
	foreach my $col ( 0 .. $#$line )
		{
		my $score = $Score[$row][$col]  || 0;
		my $char  = $Matrix[$row][$col];

		#print "[$char$score] ";
		}

	#print "\n";
	}

=cut 	

my $count = 0;
my @Names = ();
my $basename = basename( $ARGV[0] );

while( $count < $#Matrix )
	{
	my $left = $#Matrix - $count;
	my $name = "$basename-$count-";
	my $height = $left > PAGE_LENGTH ? PAGE_LENGTH : $left;
	
	my $gd = GD::Image->new( map { $_ * SCALE_FACTOR } ($height, $Longest) );
	
	my @colors = map { $gd->colorAllocate( @$_ ) } (
		[   0,   0, 255 ],
		[   0, 127, 255 ],
		[   0, 255, 255 ],
		[   0, 255, 127 ],
		[   0, 255,   0 ],
		[ 127, 255,   0 ],
		[ 255, 255,   0 ],
		[ 255, 127,   0 ],
		[ 255,   0,   0 ],
		);
		
	foreach my $row ( $count .. $count + $height - 1 )
		{
		#print "Row is $row\n";
		my $line = $Matrix[$row];
		
			
		my $x = ( $row - $count ) * SCALE_FACTOR;
		
		foreach my $col ( 0 .. $#$line )
			{
			my $y = ($Longest - $col) * SCALE_FACTOR;
			my( $x1, $y1, $x2, $y2 ) = ( 
				$x,
				$y,
				$x + SCALE_FACTOR,
				$y + SCALE_FACTOR,
				);	
						
			$gd->filledRectangle( $x1, $y1, $x2, $y2,
				$colors[ $Score[$row][$col] || 0 ] );
			}
		}
	
	$count += $height;
	$name .= "$count.png";
	push @Names, $name;

	open my($png), "> $name" or die $!;
	print $png $gd->png;
	close $png;
	}
	
open my($html), "> $basename.html" or die "$!";
print $html <<"HERE";
<HTML><HEAD><TITLE>Matrix for $ARGV[0]</TITLE></HEAD><BODY>
<H1>$ARGV[0]</h1>
<TABLE cellborder=2>
HERE

while( my $image = shift @Names )
	{
	print $html qq|\t<IMG SRC="$image/@{[time]} width=500"><br><br>\n|;
	}
	
print $html <<"HERE";
</TABLE></BODY></HTML>
HERE

sub neighbors
	{
	my( $i, $j ) = @_;
	
	foreach my $row ( $i - 1 .. $i + 1 )
		{
		next if $row < 0;
		foreach my $col ( $j - 1 .. $j + 1 )
			{
			next if $col < 0;
			next if $i == $row && $j == $col;
			no warnings;
			my $score = score( $row, $col );
			$Score[$i][$j] += score( $row, $col );
			}
		}
	}
	
sub score
	{
	no warnings;
	
	my( $i, $j ) = @_;
	my $score = 0;
	
	$score = EDGE_SCORE       if ( $i < 0 || $j < 0 );
	$score = EDGE_SCORE       if $j > $last_line;
	
	$score = EDGE_SCORE       if $#{ $Matrix[$i] } < $j;
	
	$score = WHITESPACE_SCORE if $Matrix[$i][$j] =~ m/\s/;
	$score = CHAR_SCORE       if $Matrix[$i][$j] =~ m/\S/;
	
	return $score;
	}