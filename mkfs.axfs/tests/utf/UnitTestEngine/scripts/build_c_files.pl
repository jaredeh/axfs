#!/usr/bin/perl 
# use strict;
use Cwd;
use Cwd 'abs_path';
use File::Spec;

my $rootpath;
my $cpath;
my @cpathparts;
my $srcpath;
my $cfile;
my $c;
my $root;
my $script;
my $orig_src_dir;
my $target;
my $input;
my $make;
my $funcpath;
my $cfilepath;
my @functions;

sub usage();
sub printheader($);

if($#ARGV ne 0) { usage(); }
$target = $ARGV[0];

if( ($target ne "all") and ($target ne "deepclean") and ($target ne "compile_test") ) {
	usage();
}

# finds the root of utf
$root = abs_path($0);
$root =~ s/UnitTestEngine[\/\\]scripts[\/\\]build_c_files.pl$//;

$cpath = getcwd;
my @cpathparts = split /[\/\\]/ , $cpath;
$cfile = pop (@cpathparts);

$copyscript = File::Spec->catfile($root,"UnitTestEngine","scripts","copy_source_files.pl");
$splitscript = File::Spec->catfile($root,"UnitTestEngine","scripts","split_c_file.pl");
$srcpath = File::Spec->catfile($cpath,"src");
$funcpath = File::Spec->catfile($cpath,"Functions");
$cfilepath = File::Spec->catfile($srcpath,$cfile);

chdir($cpath);

$make = "colormake";

if($target eq "all") {
	chdir($srcpath);
	system "perl ".$copyscript." source copy";
} elsif ($target eq "deepclean") {
	chdir($srcpath);
	system "perl ".$copyscript." source ".$target;
	system "$make $target CFILE=$cfile";
	print "\n";
	chdir($cpath);
} elsif ($target eq "compile_test") {
	chdir($srcpath);
	system "perl ".$copyscript." source copy";
	system "$make CFILE=$cfile";
	exit;
} 

chdir($funcpath);
opendir(FUNCDIR,$funcpath);
@functions = readdir(FUNCDIR);
foreach $function (@functions) {
	if((!($function =~ m/^\./)) and (-d $function)) {
		push @tempfunc , $function;
	}
	if((-f $function) and ($target eq "deepclean")) {
		unlink $function;
	}
}
@functions = @tempfunc;
closedir(FUNCDIR);

foreach $function (@functions) {
	printheader("$function()");
	chdir(File::Spec->catfile($funcpath,$function,"src"));
	if($target ne "deepclean") {
		system "perl ".$splitscript." ". $cfilepath." function.c ".$function."\n";
	}
	chdir(File::Spec->catfile($funcpath,$function));
	system "$make $target FUNCTION=$function";
	print "----------------------------------------------------------\n";
	print "\n";
}

######### SUBROUTINE ############

sub usage() {
	print "Bad input: ".$target."\n";
	print "Your input choices to run the script can be (case sensitive):\n";
	print "\t1) all\n";
	print "\t2) deepclean\n";
	print "\t3) compile_test\n";
	exit;
}

sub printheader($) {
	my $happy = shift @_;
	my $count;

	print "-------- ";
	print $happy;
	print " ";
	for($count = 0; $count < (48-length $happy);$count++) {
		print "-";
	}
	print "\n";
}
