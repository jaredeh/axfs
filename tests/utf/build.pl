#!/usr/bin/perl 
# use strict;
use Cwd;
use Cwd 'abs_path';
use File::Spec;

my $version = 2.3;

my $target;
my $root;
my $cpath;
my $action;
my $cfile;
my $buildscript;
my $gencfilesscript;
my $genfunctionscript;
my $topbuild;
my $genargs;
my @cfiles;
my @tempfiles;

sub usage();
sub printmajor($);
sub printminor($);

$target = $ARGV[0];

if( ($target ne "tests") and ($target ne "clean") and ($target ne "compile_test") and ($target ne "rebuild") and ($target ne "gencfile") and ($target ne "genfunction")) {
	usage();
}

foreach $arg (@ARGV) {
	if(($arg ne $target) and ($target eq "gencfile")) {
		$arg =~ s/(\,[\w\\\/\.]+)//;
		$arg = abs_path($arg);
		$genargs = $genargs ." ". $arg.$1;
	} elsif (($arg ne $target) and ($target eq "genfunction") ){
		$genargs = $genargs ." ". $arg;
	}
}

# finds the root of utf
$root = abs_path($0);
$root =~ s/[\/\\]build.pl$//;

$cpath = File::Spec->catfile($root,"c_files");
$utepath = File::Spec->catfile($root,"UnitTestEngine");
$buildscript = File::Spec->catfile($root,"UnitTestEngine","scripts","build_c_files.pl");
$gencfilesscript  = File::Spec->catfile($root,"UnitTestEngine","scripts","generate_c_file_dir.pl");
$genfunctionscript  = File::Spec->catfile($root,"UnitTestEngine","scripts","generate_function_dir.pl");

$topbuild = abs_path($0);

chdir($cpath);

$make = "make";

if($target eq "tests") {
	printmajor("Building the tests");
	printminor("Building the UnitTestEngine");
	chdir($utepath);
	$target = "all";
	system "$make $target";
	print "**********************************************************\n\n";
	$action = "Building";
} elsif ($target eq "clean") {
	printmajor("Cleaning all the directories");
	printminor("Cleaning the UnitTestEngine");
	unlink(File::Spec->catfile($root,"build.pl~"));
	chdir($utepath);
	system "$make $target";
	print "**********************************************************\n\n";
	$target = "deepclean";
	$action = "Cleaning"
} elsif ($target eq "compile_test") {
	printmajor("Compiling the original sources");
	$action = "Compile Testing";
} elsif ($target eq "rebuild") {
	system "perl $topbuild clean";
	system "perl $topbuild tests";
	exit;
} elsif ($target eq "gencfile") {
	printmajor("Creating new c_file directory");
	system "perl $gencfilesscript $genargs";
	print "##########################################################\n";
	exit;
} elsif ($target eq "genfunction") {
	printmajor("Creating new function directory");
	system "perl $genfunctionscript $genargs";
	print "##########################################################\n";
	exit;
}

chdir($cpath);

if ($#ARGV > 0) {
	push @cfiles , $ARGV[1];
} else {
	opendir(CDIR,$cpath);
	@cfiles = readdir(CDIR);
	closedir(CDIR);
}

foreach $cfile (@cfiles) {
	if((!($cfile  =~ m/^\./)) and (-d $cfile)) {
		push @tempfiles , $cfile;
	}
	if((-f $cfile) and ($target eq "clean")) {
		unlink $cfile;
	}
}
@cfiles = @tempfiles;

foreach $cfile (@cfiles) {
	printminor( "$action $cfile");
	chdir(File::Spec->catfile($cpath,$cfile));
	system "perl $buildscript $target\n";
	print "**********************************************************\n\n";
}
print "##########################################################\n";


########### SUBROUTINES ############
sub usage() {
	print "build.pl version: $version\n";
	print "Bad input: ".$target."\n";
	print "Your input choices to run the script can be (case sensitive):\n";
	print "  1) tests\n";
	print "  2) clean\n";
	print "  3) rebuild\n";
	print "  4) compile_test\n";
	print "  5) gencfile /root/foo.c [/root/inc/foo1.h /root/inc/foo2.h ...]\n";
	print "  6) genfunction foo.c bar \# for function bar() in foo.c\n";
	exit;
}

sub printmajor($) {
	my $happy = shift @_;
	my $count;
	
	print "##########################################################\n";
	print "############### ";
	print $happy;
	print " ";
	for($count = 0; $count < (41-length $happy);$count++) {
		print "#";
	}
	print "\n\n";
}

sub printminor($) {
	my $happy = shift @_;
	my $count;

	print "******* ";
	print $happy;
	print " ";
	for($count = 0; $count < (49-length $happy);$count++) {
		print "*";
	}
	print "\n";
}

