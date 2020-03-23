
use XML::LibXML;
use XML::LibXML::XPathContext;


#=======================================
# WF_sum_instrument.pl
#
# Script to extract Pacbio instrument data.
#
# ======================================

$def_loc = "smrt/movie_metadata";

if(! -d $def_loc){
	print "[FATAL] Could not find Pacbio movie metadata folder ...\n";
	exit;
}

print "[Pacbio Run Info]\n";
print "#Field: Instrument, RunID, Well, Sample Name, Start, Chemistry, Control\n";

my $num_cells = 0;

opendir(DIR, $def_loc);
while($f = readdir(DIR)){
	if($f !~ m/xml/){
		next;
	}

	$path = $def_loc . "/" . $f;
	#print $path . "\n";
	my $parser = XML::LibXML->new();
	my $xmldoc = $parser->parse_file($path);
	my $xpc = XML::LibXML::XPathContext->new($xmldoc);
	$xpc->registerNs('pb',  'http://pacificbiosciences.com/PAP/Metadata.xsd');

	my $node = $xpc->findnodes('//pb:Metadata//pb:Run//pb:RunId');
	$runid = $node->to_literal() ;

	my $node = $xpc->findnodes('//pb:Metadata//pb:InstrumentName');
	$instrument = $node->to_literal() ;

	my $node = $xpc->findnodes('//pb:Metadata//pb:Primary//pb:ConfigFileName');
	$chemistry = $node->to_literal() ;

        my $node = $xpc->findnodes('//pb:Metadata//pb:Run//pb:WhenStarted');
	$start = $node->to_literal() ;

        my $node = $xpc->findnodes('//pb:Metadata//pb:Sample//pb:Name');
	$sample = $node->to_literal() ;

        my $node = $xpc->findnodes('//pb:Metadata//pb:Sample//pb:WellName');
	$wellname = $node->to_literal() ;

        my $node = $xpc->findnodes('//pb:Metadata//pb:Sample//pb:DNAControlComplex');
	$control = $node->to_literal() ;

	print $instrument . "\t" . $runid . "\t" . $wellname . "\t" . $sample . "\t" . $start . "\t" . $chemistry . "\t" . $control . "\n";

	$num_cells++;
}

print "\n#Total SMRT Cell(s): " . $num_cells . "\n";

