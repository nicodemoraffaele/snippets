# Script to check mempool, wait n seconds and if needed generate new block 
#
# Parameters:
# -b: to specify the bitcoin-cli command path (ex. 'bitcoin-cli -conf=regtest/bitcoin.conf')
# -v: set to 1 to enable the verbose log mode (default 0)
# -s: to specify the seconds to wait (default 2)
#
# Sample usage: 
# on Windows: perl C:\my\script\path\checkMemPool.pl -b "C:\my\bitcoin\path\bitcoin-cli.exe -conf=\"C:\my\conf\file\path\regtestbitcoin.conf\"" -v 1 -s 3
# on Linux:  perl checkMemPool.pl -b 'bitcoin-cli -conf=/my/conf/path/bitcoin.conf' -v 1 -s 3
#
# Prerequisites:
# - Perl (you can install it from http://strawberryperl.com/ or https://www.activestate.com/activeperl/downloads)
# - JQ (you can install it from https://stedolan.github.io/jq/download/)
#

use 5.022;
use warnings;
use Getopt::Long;
use experimental 'signatures';
use Time::HiRes qw(gettimeofday);
use Time::Piece;

$SIG{'INT'}  = \&handler;
$SIG{'QUIT'} = \&handler;

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

sub handler {   # 1st argument is signal name
	my($sig) = @_;
	say "\n\nCaught a SIG$sig--shutting down\nbye bye!";
	#close(LOG);
	exit(0);
}
