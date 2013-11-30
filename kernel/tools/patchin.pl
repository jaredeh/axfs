#!/usr/bin/perl -w
#About this script:
#
#It was written to avoid having to modify the unreadable
#monster that is patchin.sh. Shell scripts should not be
#that long.
#
#Anyway, this is heavily commented and uses perl, which
#is almost as prevalent as bash on Linux systems and
#seeing as how the kernel itself is dependent on perl for
#a number of its utilities, it's probably a safe bet to
#be able to rely on it being present. Requires perl 5.10.
use Switch;
use File::Copy;
use Fcntl ':mode';
use Tie::File;
use FindBin qw($Bin);
use Cwd;

$cwd = getcwd;
my $Base = join("/",$Bin,"..");
my $majver = 1;
my $minver = 1;
my $subver = 1;
my $kernelver = "";

sub print_help
{
	print "Patchin Script\n";
	print "Run the patchin script while in the root of the kernel\n";
	print "you wish to patch into. Paths will be determined automatically.\n";
	print "By default, patchin will use softlinks for all files.\n";
	print "\n";
	print "Usage: patchin.pl [OPTION] [PATH]\n";
	print " --copy			Add via copy.\n";
	print " --link			Add via softlink.\n";
	print " --stock			Some older kernel need patches from stock just to build.\n";
	print " --assume-yes		Assume yes to all questions\n";
	print " --assume-subver <NUM> 	Assume we are patching against kernel minor version NUM\n";
	print "\n";
	print "[PATH] should point to a kernel directory, otherwise the current\n";
	print "working directory will be assumed to be the desired kernel directory\n";
}

sub parse_args
{
	foreach $arg (0 .. $#ARGV) {
		switch ($ARGV[$arg]) {
			my $opt = $ARGV[$arg];
			case ("--copy") { $insert_type = "copy"; }
			case ("--link") { $insert_type = "link"; }
			case ("--help") { print_help(); exit;}
			case ("--assume-yes") { $assume_yes = 1; }
			case ("--assume-subver") { $assume_subver = 1; }
			case ("--stock") { $stock = 1; }
			case (/^\d*$/) { if ($assume_subver) { $assume_subver = $opt; } }
			case (/^[\/|\.|\w].*/) { $path = $opt; }
			else { print "don't know option $opt\n"; }
		}
	}
}

sub get_kernel_version
{
	my $file = open(FH, join("/",$path,"Makefile"));
	if ($file) {
		my $maj_vstr = readline(FH);
		my $min_vstr = readline(FH);
		my $sub_vstr = readline(FH);
		close(FH);
		chomp($majver = (split(/ /, $maj_vstr))[2]);
		chomp($minver = (split(/ /, $min_vstr))[2]);
		chomp($subver = (split(/ /, $sub_vstr))[2]);
		$kernelver = "v".$majver.".".$minver.".".$subver
	}
}

sub set_target
{
	if ($path eq "") {
		$path = $cwd;
	}
}

# 2 parameters
# - Identifier to look for
# - Array to find it in
#
# We handle the parameters oddly to force
# the second to be recognized as an array.
sub do_find_index_in_file
{
	my $ind = -1;
	my ($id, @lines) = @_;
	foreach (0 .. $#lines) {
		if ($lines[$_] =~ m/(\Q$id\E)/ ) {
			$ind = $_;
		}
	}
	return $ind;
}

# 3 parameters
# - File to source, and file to patch
# - Identifier for line after which the line is to be
#   inserted/
# - Line to patch into the file.
sub do_patch_line
{
	my $expath = join("/",$path,$_[0]);
	print "Patching file $expath\n";
	# Tie is pretty nifty.
	tie my @lines, 'Tie::File', $expath;
	my $id = $_[1];
	my $insert = $_[2];
	my $index = -1;

	$index = do_find_index_in_file($insert,@lines);
	if ($index > -1) {
		die "File $expath already patched.\n";
	}
	
	$index = do_find_index_in_file($id,@lines);
	if ($index == -1) {
		die "Couldn't find $id in $expath\n";
	}

	splice(@lines,($index + 1), 0, "$insert");
	untie @lines;
}

# 2 parameters
# - File to source, and file to patch
# - Identifier for line after which the contents of the
#   source file are to be placed.
sub do_patch_file
{
	my $id = $_[1];
	my $expath = join("/",$path,$_[0]);
	my $srcpath = join("/",$Base,$_[0]);

	print "Splicing file $srcpath into $expath\n";

	tie my @existing, 'Tie::File', $expath;
	tie my @source, 'Tie::File', $srcpath;

	if (do_find_index_in_file($source[0],@existing) > -1) {
		die "File $expath is already spliced\n";
	}

	$index = do_find_index_in_file($id,@existing);

	splice(@existing,($index),0,@source);

	untie @existing;
	untie @source;
}

sub link_file
{
	print "Linking file: $_[0] -> $_[1]\n";
	symlink($_[0],$_[1]);
}

sub copy_file
{
	print "Copying file: $_[0] -> $_[1]\n";
	copy($_[0],$_[1]);
}

sub do_process_dir
{
	my $filedir = $_[0];
	my $fileroot = join("/",$Base,$filedir);
	my $filedest = join("/",$path,$filedir);

	if ( ! -e $filedest) {
		mkdir($filedest);
	}

	opendir(INDIR, $fileroot);
	while ( defined ( my $file = readdir(INDIR))) {
		if (grep(/^\.\.*$/,$file) > 0) {
			next;
		}
		$src = join("/",$fileroot,$file);
		$dst = join("/",$filedest,$file);
		if ( -d $src ) {
			do_process_dir(join("/",$filedir,$file));
			next;
		}
		switch($insert_type) {
			case ("link") { link_file($src,$dst); }
			case ("copy") { copy_file($src,$dst); }
		}
	}
}

# When given a directory, will ensure that the directory named
# exists in the target location. It will then either link or
# copy every file in that directory to the other directory.
sub do_insert_files
{
	my $filedir = $_[0];
	do_process_dir($filedir);
}

# Looks for patches that associate with this kernel version
# and then applies them to our kernel.
sub do_kernel_patches
{
	my $expath = $path;
	my $srcpath = join("/",$Base,$_[0],$kernelver);
	my @files;

	opendir(DIR, $srcpath);
	while (my $file = readdir(DIR)) {
		# We only want files
		next unless (-f "$srcpath/$file");
		push @files, "$srcpath/$file";
	}
	closedir(DIR);

	foreach (sort @files) {
		system("patch -p1 -i $_ -d $path") == 0
		or die "system @args failed: $?"
	}
}

$insert_type = "link";
$path = "";
$patching_project = "AXFS";
$assume_yes = 0;
$stock = 0;

parse_args();
set_target();
get_kernel_version();

if ($stock == 1) {
	do_kernel_patches("patches/stock_patches");
	exit;
}

if ($assume_yes != 1) {
	print "Patching $patching_project into linux-$majver.$minver.$subver.\n";
	print "Using method: $insert_type\n";
	print "Proceed? [Y/n]: ";
	$resp = readline(*STDIN);

	if (grep(/[n|N]/,$resp) > 0) {
		exit;
	}
}

if ($minver > 5 || $assume_subver > 5) {
	do_kernel_patches("patches");
	do_patch_line("fs/Makefile", "CONFIG_CRAMFS", "obj-\$(CONFIG_AXFS)		+= axfs/");
	do_patch_file("fs/Kconfig", "config ECRYPT_FS");
	do_insert_files("fs/axfs");
	do_insert_files("include/linux");
}
