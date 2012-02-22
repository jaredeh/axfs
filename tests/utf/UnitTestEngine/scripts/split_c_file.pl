#!/usr/bin/perl 
# use strict;
use Cwd;

$parse_file = $ARGV[0]; # the original file
$out_file = $ARGV[1];   # the split out file
$function = $ARGV[2];   # the function we are looking for

# globals
$line;
$found;
@prefunction;
@foundfunction;
$o_curvy = 0;
$o_curly = 0;
$c_curvy = 0;
$c_curly = 0;

# space the file so the function in the split out file
# lines up with those in the real file when = 1
$orig_line_num = 1;

# prints special debug messages when = 1
$debug = 0;

if($debug)
{
	# print out ARGV and PWD to make debugging script failures easier
	print "ARGV = (\n\t", join("\n\t", @ARGV), "\n)\n";
	print "pwd = ", getcwd, "\n";
}


## begin main ##

print ("Splitting $function() out of $parse_file to $out_file\n");
open (OUTFILE, "> $out_file") || die "Can't open $out_file for writing: $!";
open (PARSEFILE, "< $parse_file") || die "Can't open $parse_file for reading: $!";

@lines = <PARSEFILE>;
close(PARSEFILE);
@clines = @lines;

# remove comments from a copy of the ot file so we can 
# disregard any confusing stuff in the comments
RemoveComments();

# find the function and decode syntax
for($i=0;$i<($#lines+2);$i++){
	$found = 0;
	$line = $clines[$i];
	$rline = $lines[$i];
	if($debug) {print "i$i: $rline";}

	# print any preprocessor lines other than include (unless function found, will print below)
	if(($line =~ m/^\s*\#/) && !($line =~ m/\#include/) && !found) {
		print OUTFILE "$line";
		next;
	}

	# finding function name we wish to extract
	if($line =~ m/$function\b/ && !LineIsFunctionPointer($line, $function)){ 
		$found = 1;
	}

	# find any lines above the function declaration
	CatchFunctionBeginning();

	# loop once we found the function
	while($found){
		$line = $clines[$i];
		$rline = $lines[$i];		
		if($debug) {print "i$i function found: $rline";}

		# looking for the curved brackets that signify a 
		#   function or protoype declaration
		FindCurvyBrackets();

		# looking for the curly brackets that signify the 
		#   beginning of a function
		FindCurlyBrackets();
		$i++;		
	}
	
	# Decide what and how to output
	Output();
}
close(OUTFILE);

## end main ##


#### subfunctions ####

sub Output {
	# we have the function now we decide what to do
	if($found){
		# print out the function
		if($orig_line_num){
			foreach $line (@prefunction){
				seek OUTFILE,-length("\n"),1;
			}
		}
		foreach $line (@prefunction){
			print OUTFILE $line;
		}
		undef @prefunction;
		foreach $line (@foundfunction){
			print OUTFILE $line;
		}
		undef @foundfunction;
	}
	# not the function either print out white space or not
	if(not $found){
		if(not defined(@prefunction) and not defined(@foundfunction)){
			if($orig_line_num){
				print OUTFILE "\n";
			}
		}
		if(defined(@foundfunction)){
			foreach $line (@foundfunction){
				print OUTFILE "\n";
			}
			undef @foundfunction;
		}
		undef @prefunction;
	}
}



sub CatchFunctionBeginning{
	# looping up to include function comments and type declarations
	if($found) {
		my $littleline = $rline;
		$littleline =~ s/$function.*//;
		if($littleline =~ m/[^\*\w\n\s]/){last;}
		$j = 1;
		while($i-$j){
			$backline = $clines[$i-$j];
			$rbackline = $lines[$i-$j];
			if($debug) {print "i$i j$j $rbackline";}
			if($backline =~ m/[^\*\w\n\s]/){last;}
			unshift @prefunction, $rbackline;
			$j++;
		}		
	}
}



sub FindCurvyBrackets {
	# prototypes or beginning of function 
	$o_curvy += countchar($line,"\\(");
	$c_curvy += countchar($line,"\\)");
	if(($c_curvy)and($o_curvy eq $c_curvy)){
		# just a single line prototype or function call
		if($line =~ m/\)\s*\;/){
			if($debug) {print "proto func: $rline";}
			push @foundfunction, $rline;
			$found = 0;
			last;
		}
		push @foundfunction, $rline;
		if($debug) {print "i$i curvy $o_curvy,$c_curvy same line as function: $rline";}
	}elsif($o_curvy or $c_curvy) {
		push @foundfunction, $rline;
		if($debug) {print "i$i curvy $o_curvy,$c_curvy: $rline";}
	}
	while(($o_curvy-$c_curvy)and($i<($#lines+2))){
		$i++;
		$line = $clines[$i];
		$rline = $lines[$i];
		$o_curvy += countchar($line,"\\(");
		$c_curvy += countchar($line,"\\)");
		push @foundfunction, $rline;
		if($debug) {print "i$i curvy $o_curvy,$c_curvy: $rline";}
		if($i eq ($#lines+2)) {die("eof before function closed\n")}
	}
	$o_curvy = $c_curvy = 0;
	if($line =~ m/\)\s*\;/){
		if($debug) {print "proto func: $rline";}
		$found = 0;
		last;
	}
}



sub FindCurlyBrackets {
	# loop until the close of a function
	$o_curly += countchar($line,"\\{");
	$c_curly += countchar($line,"\\}");
	if(countchar($line,"\\)")) {
		if($debug) {print "i$i curvy ends, curly start line func: $rline\n";}
	} elsif(($c_curly)and($o_curly eq $c_curly)){
		if($debug) {print "i$i curvy open/close same line func: $rline\n";}
		push @foundfunction, $rline;
	} elsif($o_curly or $c_curly) {
		push @foundfunction, $rline;
		if($debug) {print "i$i curly $o_curly,$c_curly: $rline";}
	}
	while(($o_curly-$c_curly)and($i<($#lines+2))){
		$i++;
		$rline = $lines[$i];
		$line = $clines[$i];
		$o_curly += countchar($line,"\\{");
		$c_curly += countchar($line,"\\}");
		push @foundfunction, $rline;
		if($debug) {print "i$i curly $o_curly,$c_curly: $rline";}
	}
	if(($o_curly)and($o_curly eq $c_curly)){
		$o_curly = $c_curly = 0;
		last;
	}

}



sub countchar {
	my($charline,$char)=@_;
	my $retval = 0;
	while($charline =~ m/$char/g){
		$retval++;
	}
	return $retval;
}



sub RemoveComments {
	# remove block comments
	for($i=0;$i<$#clines;$i++){
		$found = 0;
		$cline = $clines[$i];
		# single line comments
		while($cline =~ s/\/\*.*?\*\// /) {
			$clines[$i] = $cline;
			next; 
		}
		# multiline comments
		if($cline =~ s/\/\*.*/ /){
			$found = 1;
			$clines[$i++] = $cline;
		}
		while($found){
			$cline = $clines[$i];
			if($cline =~ s/.*?\*\// /){ $found = 0;}
			else {$cline = "\n";}
			$clines[$i++] = $cline;
		}
	}

	# remove line comments
	for($i=0;$i<$#clines;$i++){
		$cline = $clines[$i];
		# single line comments
		if($cline =~ s/\/\/.*/ /) {
			$clines[$i] = $cline;
		}
	}
}

# check to see if line uses function as a pointer, for example
# if function address is being stored in a struct member
sub LineIsFunctionPointer {
	my ($code_line, $func) = @_;

	# .struct_member1   =  <function>
	if($code_line =~ /\.*[a-zA-Z_][a-zA-Z_0-9]*\s*=\s*$func/)
	{
		return 1;
	}
	# pass as function pointer, or un-named struct member
	# func1(a, b, <function>,) or func1(a, b, <function>)
	if($code_line =~ /$func\s*,/ or $code_line =~ /$func\s*\)/)
	{
		return 1;
	}


	return 0;
}
