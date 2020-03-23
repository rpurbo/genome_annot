$file=$ARGV[0];

## Fields: query acc.ver, subject acc.ver, % identity, query length, subject length, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score

my %tops;
my %records;

open(FILE,$file);
while($buff=<FILE>){
	if(substr($buff,0,1) eq "#"){
		next;
	}

	chomp $buff;
	@tok = split(/\t/,$buff);
	$bit = $tok[scalar(@tok) - 1];
	$query = $tok[0];	

	if($tops{$query} eq "" || $bit > $tops{$query}){
		$tops{$query} = $bit;
		$records{$query} = $buff;
	}
}

close(FILE);

print "#Fields: query, subject, query len, aln%, ident%, e-value, bit-score\n";
for $query (sort {$tops{$a} <=> $tops{$b}} keys %tops){
	$buff = $records{$query};
	@tok = split(/\t/,$buff);
	$que = $tok[0];
	$subj = $tok[1];
	$ident = sprintf("%.2f", $tok[2]);
	$qlen = $tok[3];	
	$slen = $tok[4];
	$aln = $tok[5];
	$eval = $tok[12];
	$bit = $tok[13];

	$alnperc = sprintf("%.2f",($aln / $slen) * 100);
	if($alnperc > 100){
		$alnperc = 100;
	}

	print $query . "\t" . $subj . "\t" . $qlen . "\t" . $alnperc . "\t" . $ident . "\t" . $eval . "\t" . $bit . "\n";
}
