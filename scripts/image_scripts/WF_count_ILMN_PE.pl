#=======================================
## WF_count_ILMN_PE.pl
##
## Script to get Illumina reads stats
##
## ======================================



$read1 = $ARGV[0];
$read2 = $ARGV[1];

my $reads_cnt = 0;
my $bases = 0;

open (FILE, $read1);
while($buff = <FILE>){
	if(substr($buff,0,1) eq "@"){
		$header = $buff;
		$buff = <FILE>;
		$read = $buff;
		$buff = <FILE>;
		$buff = <FILE>;
                $qual = $buff;

		$reads_cnt++;
		$bases += length(trim($read));
	}
}
close (FILE);

open (FILE, $read2);
while($buff = <FILE>){
        if(substr($buff,0,1) eq "@"){
                $header = $buff;
                $buff = <FILE>;
                $read = $buff;
                $buff = <FILE>;
                $buff = <FILE>;
                $qual = $buff;

                $reads_cnt++;
                $bases += length(trim($read));
        }
}
close (FILE);

$avglen = $bases/$reads_cnt;

print "[ILMN Reads Info]\n";
print "ILMN Paired Read Count," . ($reads_cnt/2) . "\n";
print "ILMN Total Bases," . ($bases) . "\n";
print "ILMN Mean Length," . ($avglen) . "\n";



sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
