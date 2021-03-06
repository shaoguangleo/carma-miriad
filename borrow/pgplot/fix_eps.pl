#!/usr/bin/perl -w
use strict;

#fix_eps.pl
#version 1.1
#Copyright 2003,2004 John C. Vernaleo
#Unfortunately, I am not comfortable putting unobscured email addresses
#on the web, but these shouldn't be too hard to figure out.
#
#		(my_first_name)@netpurgatory.com
#				or
#		(my_last_name)@astro.umd.edu
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#    See readme_fix_eps.txt for more information and a copy of the GPL

my $filename=$ARGV[0];
unless(defined($filename)){
    print "Enter file name: ";
    chomp($filename=<STDIN>);
}

&fix_eps($filename);

sub fix_eps {
    my ($file)=(@_);
    my $fix=1;
    open DATA, "< $file" or die("cannot open $file: $!");
    my @data=<DATA>;
    close DATA;
    foreach(@data){
	if($_=~/%%Pages: 1[\s]/){
	    $fix=0;
	}
    }
    if($fix==0)
    {
	print "Single Page File\nNo modification needed.\n";
    }
    if($fix!=0)
    {
	print $fix,"\n";
	print "Multiple Page File\n";
	@ARGV=$file;
	$^I="~";
	while(<>) {
	    s/%!PS.*/%!PS-Adobe-3.0/;
	    print;
	}
	print "Removed Encapsulated Postscript statement if present\n";
    }
}
1;
