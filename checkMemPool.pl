use 5.022;
use warnings;
use Getopt::Long;
use experimental 'signatures';
use Time::HiRes qw(gettimeofday);
use Time::Piece;

Getopt::Long::Configure qw(gnu_getopt);

#default params
my $secondToWait = 2;
my $bc = "bitcoin-cli";
my $verbose = 0;

#get params
GetOptions
(
        'secondToWait|s=s'     => \$secondToWait,
        'bc|b=s'        => \$bc,
                'verbose|v=s'   => \$verbose
) or die "err options!\n";

#output params
debug("Executing script $0\n");
debug("parameters:");
debug("bc: $bc");
debug("secondToWait: $secondToWait");
debug("verbose: $verbose");

while (1)
{
	my $mempoolTXs = join '', exe("getmempoolinfo | jq .size");
	debug("MemPool size: " . $mempoolTXs . "\r");
	if (not ($mempoolTXs > 0))
	{
		#sleep 1;
		debug("There are NO tx in mempool\r");
		next;
	}

	debug("There are tx in mempool: " . $mempoolTXs);
	
	debug("Storing mempool txs in a variable...");
	my @currTXS = grep {/[^\[\]]/} exe("getrawmempool");
	debug("Before waiting: " . scalar(@currTXS));
	
	
	debug("Wait $secondToWait seconds...");
	sleep $secondToWait;
	
	debug("Storing new mempool txs in a var");
	my @newTXS = grep {/[^\[\]]/} exe("getrawmempool");
	debug("After waiting: " . scalar(@newTXS));
	
	debug("Check intersection between arrays");
	my %currTXS = map{$_ =>1} @currTXS;
	my @intersection = grep{$currTXS{$_}} @newTXS;
	
	debug("If intersection greater then 0, generate new block");
	debug("Intersection: " . scalar(@intersection));
	if (@intersection)
	{
		# debug("Log intersection..");
		# foreach(@intersection)
		# {
			# debug("$_\r\n");
		# }
		
		stamp("Generating new block at: " . localtime->strftime('%F %T'));
		my @blockHash = exe("generate 1");
		stamp("New block generated! Hash: " . $blockHash[1]);
	}
	else
	{
		debug("No block to generate");
	}

}

#FUNCTIONS
sub exe($cmd)
{
        chomp(my @out = `$bc $cmd`);
        return @out;
}

sub debug($data)
{
	$data .= "\n" if $data !~ /\r$/;		
	print $data if $verbose == 1;
}

sub stamp($data)
{
	say $data;
    open my $fh, '>>', "checkMemPool.log" or die "error opening file $!\n";
    flock $fh, 2;
    say $fh "$$-" . $data;
}
