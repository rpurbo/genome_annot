

#=======================================
# WF_sum_annot.pl
#
# Script to extract genome annotation data.
#
# ======================================

$def_loc = "04_features/annot.txt";
$def_loc2 = "04_features/annot.tsv";

if(! -f $def_loc){
	print "[FATAL] Could not find genome annotation report ...\n";
	exit;
}

print "[Genome Features Annotation Data]\n";

print "\n#====== [Summary] ======\n";

open(FILE,$def_loc);
$buff=<FILE>;
$buff=<FILE>;
$buff=<FILE>;
while ($buff=<FILE>) { 
	chomp $buff;
	$buff =~ s/:/,/g;
	print $buff . "\n";
}
close(FILE);
print "\n";

my %db;
open(FILE,$def_loc2);
$header=<FILE>;
while ($buff=<FILE>) {
	chomp $buff;
	@tok = split(/\t/,$buff);
	$type = $tok[1];
	$product = $tok[6];

	if($type eq "tRNA"){
		$product =~ m/(.+)\(.+\)/;
		$product = $1;
	}

	if($type eq "CDS"){
		if($product eq "hypothetical protein"){
			next;
		}

		if($product eq "putative protein"){
			next;
		}
	}

	$db{$type}{$product}++;
}
close(FILE);

print "#====== [rRNA] ======\n";
for $prod (sort { $db{"rRNA"}{$b} <=>  $db{"rRNA"}{$a}}keys %{$db{"rRNA"}}){
	print $prod ."," . $db{"rRNA"}{$prod} . "\n";
}

print "\n";
print "#====== [tRNA] ======\n";
for $prod (sort { $db{"tRNA"}{$b} <=>  $db{"tRNA"}{$a}} keys %{$db{"tRNA"}}){
        print $prod ."," . $db{"tRNA"}{$prod} . "\n";
}


print "\n";
print "#====== [misc_RNA] ======\n";
for $prod (sort { $db{"misc_RNA"}{$b} <=>  $db{"misc_RNA"}{$a}} keys %{$db{"misc_RNA"}}){
        print $prod ."," . $db{"misc_RNA"}{$prod} . "\n";
}

print "\n";
print "#====== [CDS (top 20 products excl. hypothetical/putative) ] ======\n";
$cnt = 30;
for $prod (sort { $db{"CDS"}{$b} <=>  $db{"CDS"}{$a}} keys %{$db{"CDS"}}){
        print $prod ."," . $db{"CDS"}{$prod} . "\n";
	$cnt--;
	if($cnt==0){last;}
}





