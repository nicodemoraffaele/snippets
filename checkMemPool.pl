use 5.022;
use warnings;
use experimental 'signatures';

my $secondToWait = 2;
my $bc = "bitcoin-cli";

while (1)
{
	my $mempoolTXs = join '', exe("getmempoolinfo | jq .size");
	if (not ($mempoolTXs > 2))
	{
		say "There are NO tx in mempool";
		next;
	}
	
	say "There are tx in mempool: " . $mempoolTXs;		
	say "Store mempool txs in a var";
	my @currTXS = exe("getrawmempool");
	my %currTXS = map{$_ =>1} @currTXS;
	say "currTXS: " . keys(%currTXS);
	say "Wait $secondToWait seconds...";
	sleep $secondToWait;
	say "Store new mempool txs in a var";
	my @newTXS = exe("getrawmempool");
	say "new: " . scalar(@newTXS);
	say "Check intersection between arrays";
	my @intersection = grep{$currTXS{$_}} @newTXS;
	say "If intersection greater then 0, generate 1";
	say "Intersection length: " . $#intersection;
	if (@intersection)
	{
		say "Generate new block";
		my $blockHash = exe("generate 1");
	}
	else
	{
		say "No block to generate";
	}
}

#FUNCTIONS
sub exe($cmd)
{
	chomp(my @out = `$bc $cmd`);
	return @out;
}
