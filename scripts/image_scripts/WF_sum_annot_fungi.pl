

#=======================================
# WF_sum_annot.pl
#
# Script to extract genome annotation data.
#
# ======================================

$def_loc = "04_features/annotate_results/Genus_Species.gff3";
$def_loc2 = "02_rrna/rrna.gff";

if(! -f $def_loc){
	print "[FATAL] Could not find genome annotation report ...\n";
	exit;
}

print "[Genome Features Annotation Data]\n";

my %rrnas;
my %db;

my $all_rrna=0;
my $all_trna=0;
my $all_mrna=0;

open(FILE,$def_loc2);
$buff=<FILE>;
$buff=<FILE>;
$buff=<FILE>;
while ($buff=<FILE>) { 
	chomp $buff;
	@tok = split(/\t/,$buff);
	$entry = $tok[8];
	$entry =~ m/Name=(.+?)\;/;
	$prod = $1;
	$all_rrna++;

	$db{"rRNA"}{$prod}++; 
}
close(FILE);

open(FILE,$def_loc);
$header=<FILE>;
while ($buff=<FILE>) {
	chomp $buff;
	@tok = split(/\t/,$buff);
	$type = $tok[2];
	$entry = $tok[8];

	if($type eq "tRNA"){
		$product = ""; 
		$entry =~ m/product=(.+?);/; 
		$product = $1;
		$db{"tRNA"}{$product}++;
		$all_trna++;
	}
	
	if($type eq "CDS"){
		$all_cds++;
	}

	if($type eq "mRNA"){
		$product = "";
		$entry =~ m/product=(.+?);/;
		$product = $1;
		$db{"mRNA"}{$product}++;
		$all_mrna++;	
	}

}
close(FILE);

print "\n#====== [Summary] ======\n";
print "rRNA," . $all_rrna . "\n";
print "tRNA," . $all_trna . "\n";
print "mRNA," . $all_mrna . "\n";
print "CDS," . $all_cds . "\n";
print "\n";

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
print "#====== [CDS (top 20 products excl. hypothetical/putative) ] ======\n";
$cnt = 30;
for $prod (sort { $db{"mRNA"}{$b} <=>  $db{"mRNA"}{$a}} keys %{$db{"mRNA"}}){
        print $prod ."," . $db{"mRNA"}{$prod} . "\n";
	$cnt--;
	if($cnt==0){last;}
}





