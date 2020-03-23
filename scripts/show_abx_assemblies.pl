#!/cm/shared/apps/devel/perl/5.30.0/bin/perl

use REST::Client;
use MIME::Base64;
use JSON;
use Data::Dumper;

#=============================== Annotation Workflow Template Config =======================================

$FUNGI_TEMPLATE="";
$BACTERIA_TEMPLATE="";

#============================================================================================================


#================================ SMRT Portal Connection Config =============================================

$setpoint = "http://169.254.100.24:8080";
$url = "/smrtportal/api/jobs/by-protocol/RS_HGAP_Assembly.3";
$userpass = "api_user:strange-server-access-CAPITAL99";
$options = "options={\"page\":1,\"rows\":2000,\"sortOrder\":\"desc\",\"sortBy\":\"jobId\"}&jobStatus=Completed";

#============================================================================================================

$maxitems = 20;
$all=0;

if( $ARGV[0] eq '-a'  )
{
	$all = 1;
}


my $client = REST::Client->new();
$client->setHost($setpoint);
$client->addHeader( "Authorization", "Basic ".encode_base64($userpass));
$client->POST( $url , $options);
die $client->responseContent() if( $client->responseCode() >= 300 );
my $r = decode_json( $client->responseContent() );

print "#Field: id, name, protocol, start-time, creator\n";

my %resps;
my @rows = @{$r->{"rows"} };
foreach $row ( @rows ) {
	$name = $row->{'name'};
	$protocol = $row->{'protocolName'};

	if($name =~ m/ABX/g && $protocol eq "RS_HGAP_Assembly.3"){

		$id = $row->{'jobId'};
		$created = $row->{'createdBy'}; 
		$start = $row->{'whenStarted'};
		$line = $id . "\t" . $name . "\t" . $protocol . "\t" . $start . "\t" . $created;
		$resps{$id} = $line;
	}
}

$cnt=0;
for $id (sort {$b <=> $a} keys %resps){
	print $resps{$id} . "\n";
	$cnt++;
	if($all != 1 && $cnt >= $maxitems ){
		print "...\n# use -a to show all assemblies\n";
		last;	
	}
}




