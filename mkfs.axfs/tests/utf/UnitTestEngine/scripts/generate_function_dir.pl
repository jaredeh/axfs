#!/usr/bin/perl 
# use strict;
use File::Copy;
use File::Spec;
use Cwd;
use Cwd 'abs_path';

#usage: perl generate_function_dir.pl 'c_file_name' 'function_name'

if ($#ARGV ne 1) {
	die "incorrect parameters";
}

$cfile = $ARGV[0];			# for foo.c this is foo
$function = $ARGV[1];	# for bar() in foo.c this is bar

$path = abs_path($0);
$path =~ s/UnitTestEngine[\/\\]scripts[\/\\]generate_function_dir.pl$//;

$template =  File::Spec->catfile($path,'UnitTestEngine','templates');
$path = File::Spec->catfile($path,'c_files',$cfile);

if (!(-d $path)) {
	die "directory $path does not exist - I don't know what to do!";
}

$path = File::Spec->catfile($path,'Functions', $function);

if (-d $path) {
	die "directory $path already exists - I don't know what to do!";
}

mkdir $path;
mkdir File::Spec->catfile($path,'src');
mkdir File::Spec->catfile($path,'inc');
mkdir File::Spec->catfile($path,'build');

copy(File::Spec->catfile($template,'function','stubs.c') , File::Spec->catfile($path,'src','stubs.c'));
copy(File::Spec->catfile($template,'function','stubs.h') , File::Spec->catfile($path,'inc','stubs.h'));
copy(File::Spec->catfile($template,'function','header.h') , File::Spec->catfile($path,'inc','header.h'));
copy(File::Spec->catfile($template,'function','Makefile') , File::Spec->catfile($path,'Makefile'));

open OUT, '>',File::Spec->catfile($path,'src','unittests.c') or die "couldn't write out unittests.c";
open IN, '<',File::Spec->catfile($template,'function','unittests.c') or die "couldn't read in template unittests.c";

while(<IN>) {
	$_ =~ s/EXAMPLE/$function/;
	print OUT $_;
}

close IN;
close OUT;

print "Created directory for $function in $cfile\n";