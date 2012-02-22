#!/usr/bin/perl 
# use strict;
use File::Copy;
use Cwd;
use Cwd 'abs_path';
use File::Spec;

$source_file = $ARGV[0];	# the 'source' file
$switch = $ARGV[1];			# am I going to delete or copy the file?

# globals
my @lines;
my $target  = "";

# prints special debug messages when = 1
$debug = 0;

## begin main ##
open (PARSEFILE, "< $source_file") || die "Can't open $source_file for reading: $!";
@lines = <PARSEFILE>;
close(PARSEFILE);

foreach $line (@lines) {
	my $orig = "";
	my $target  = "";
	my @originals;
	chomp $line;

	if($line =~ m/SOURCE\=\"([\.\/\w]+)\"/) {
		@originals = split /[\\\/]/ , $1;
		if(($1 =~ m/\/([\w]+\.[cm]$)/) ne 1) {die "Error:  bad source file syntax $line\n";}
		$target = $1;
	} elsif(($line =~ m/HEADER\=\"([\.\/\w]+)\"\,\"([\.\/\w]+)\"/) or ($line =~ m/HEADER\=\"([\.\/\w]+)\"/) ) {
		@originals = split /[\\\/]/ , $1;
		my @subdirs = split /[\\\/]/ , $2;
		if(($1 =~ m/\/([\w]+\.h$)/) ne 1) {die "Error:  bad source file syntax $line\n";}
		my $file = $1;
		foreach $subdir (@subdirs) {
			$target =  File::Spec->catfile($target,"$subdir");
		}
		$target =  File::Spec->catfile("..","inc",$target);
		if(!(-e $target)) {
			mkdir $target;
		}
		$target =  File::Spec->catfile($target,$file);
	}
	
	foreach $original (@originals) {
		if((($original eq "..") or ($original eq ".")) and ($orig eq "")) {
			$orig = $original;
		} else {
			$orig = File::Spec->catfile($orig,$original);
		}
	}
	$orig = abs_path($orig);
	
	if($debug eq 1) {
		print "original=".$orig."\n";
		print "target=".$target."\n\n";
	}

	if($switch eq "copy") {
		copy($orig,$target) or die "Copy of $orig to $target failed: $!";
	} elsif($switch eq "deepclean") {
		unlink($target);
	} else {
		die "Error:  bad switch $switch\n";
	}
}
