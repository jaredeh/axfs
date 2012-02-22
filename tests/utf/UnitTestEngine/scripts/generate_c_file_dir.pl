#!/usr/bin/perl 
# use strict;
use File::Copy;
use File::Spec;
use Cwd;
use Cwd 'abs_path';

sub fixup_paths ($$$);

#usage: perl generate_c_file_dir.pl 'path_to_c_file' 'path_to_project_header1' 'path_to_project_header2' .....

if ($#ARGV lt 0) {
	die "incorrect parameters";
}

foreach $arg (@ARGV) {
	$justhfile = $arg;
	$justhfile =~ s/\,[\w\\\/\.]+//;
	$test = File::Spec->catfile(split /[\/\\]/, $justhfile);
	if(!(-e $test)) {
		die "file $test doesn't exist - I give up!"
	}

	if (!defined $cfile) {
		$cfile_path = $arg;
		my @list = split /[\/\\]/ , $cfile_path;
		$cfile = pop (@list);
	} else {
		push @hfiles , $arg;
	}
}

$root = abs_path($0);
$root =~ s/UnitTestEngine[\/\\]scripts[\/\\]generate_c_file_dir.pl$//;

$template =  File::Spec->catfile($root,'UnitTestEngine','templates','cfile');

if (-d File::Spec->catfile($root,'c_files',$cfile)) {
	die "directory $cfile exisits - I refuse to touch it!";
}

$path = File::Spec->catfile($root,'c_files',$cfile);

#make directories and copy over files
mkdir $path;
mkdir File::Spec->catfile($path,'src');
mkdir File::Spec->catfile($path,'inc');
mkdir File::Spec->catfile($path,'Functions');

copy( File::Spec->catfile($template,'compile_test_stubs.c') , File::Spec->catfile($path,'src','compile_test_stubs.c')) or die "Couldn't find File::Spec->catfile($template,'compile_test_stubs.c')";
copy( File::Spec->catfile($template,'pre.h') , File::Spec->catfile($path,'inc','pre.h')) or die "Couldn't find File::Spec->catfile($template,'pre.h')";
copy( File::Spec->catfile($template,'Makefile') , File::Spec->catfile($path,'src','Makefile')) or die "Couldn't find File::Spec->catfile($template,'Makefile')";

#find if $cfile has a main()
open IN, '<',File::Spec->catfile($template,'compile_test.c') or die "couldn't read in template ".File::Spec->catfile($template,'compile_test.c');

my $hasmain = 0;
while(<IN>) {
	if($_ =~ m/\s+main\s+\(/) {
		$hasmain = 1;
	}
}
close IN;

#customize compile_test.c
open OUT, '>',File::Spec->catfile($path,'src','compile_test.c') or die "couldn't write out ".File::Spec->catfile($path,'src','compile_test.c') ;
print OUT "\n";
print OUT "#include \"$cfile\"\n";
print OUT "\n";

if ($hasmain eq 0) {
	open IN, '<',File::Spec->catfile($template,'compile_test.c') or die "couldn't read in template ".File::Spec->catfile($template,'compile_test.c');
	while(<IN>) {
		$_ =~ s/EXAMPLE/$cfile/;
		print OUT $_;
	}
	close IN;
	print OUT "\n";
}
close OUT;

#fixup the paths to the original source code
$cfile_path = fixup_paths($cfile_path,$root,$cfile);
foreach $hfile (@hfiles) {
	push @hcopy , fixup_paths($hfile,$root,$cfile);
}
@hfiles = @hcopy;

#create the source file from the inputs
open OUT, '>',File::Spec->catfile($path,'src','source') or die "couldn't write out ".File::Spec->catfile($path,'src','source') ;
print OUT "SOURCE=\"$cfile_path\"\n";
foreach $hfile (@hfiles) {
	if($hfile =~ m/([\\\/\:\w\.]+)\,([\\\/\w\.]+)/) {
		print OUT  "HEADER=\"$1\",\"$2\"\n" ;
	} else {
		print OUT "HEADER=\"$hfile\"\n";
	}
}
close OUT;

print "Created directory for $cfile\n";

############# SUBROUTINES ############
sub fixup_paths ($$$) {
	my $i = 0;
	my $j = 0;
	my $same = 0;
	my $diff = 0;
	my @pathparts;
	my @rootparts;
	my $fixpath;
	my $fixsubdir;
	my $rootfixpath;
	my $fixed = "";
	my $subdirstrip;
	my $fixpath = "";
	my $rootfixpath = "";
		
	$fixpath = shift @_;
	$rootfixpath = shift @_;
	$fixcfile = shift @_;

	if ($fixpath =~ s/(\,[\w\\\/\.]+)//) {
		$fixsubdir = $1;
	}
	
	if($fixsubdir ne "") {
		$fixsubdir =~ s/\\/\//g;
	}
	
	$fixpath =  abs_path($fixpath);
	$rootfixpath = abs_path(File::Spec->catfile($rootfixpath,'c_files',$fixcfile,'src'));

	$fixpath =~ s/^\///;
	$rootfixpath =~ s/^\///;
	
	@pathparts = split /[\\\/]/,$fixpath;
	@rootparts = split /[\\\/]/, $rootfixpath;
	
	for($i=0;$i<($#rootparts+1);$i++) {
		my $cmppath = "";
		my $cmproot = "";
		for($j=0;$j<=$i;$j++){
			$cmppath = $cmppath.$pathparts[$j];
			$cmproot = $cmproot.$rootparts[$j];
			if($cmppath eq $cmproot) {$same = $j+1;}
		}
		$diff = ($i+1) - $same;
	}
	
	if($same gt 0) {
		for($j=0;$j<$diff;$j++) {
			$fixed = $fixed . "../";
		}
		for($j=0;$j<($#pathparts-$same+1);$j++) {
			$fixed = $fixed . $pathparts[$same + $j] . "/";
		}
	} else {
		return $fixpath.$fixsubdir;
	}
	
	$fixed =~ s/\/$//;
	$fixed = $fixed.$fixsubdir;
	return $fixed;
}
