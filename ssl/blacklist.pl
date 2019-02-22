#!/usr/bin/perl
use warnings;
#use strict;
use Socket;
use Net::SMTP;

sub rev_dns_ip
{
    my @dns_nm = qw//;
    my @rev_ip = qw//;
    my $file = "C:\\SSL\\links.txt"; #in here say where the file is located (for me it is C:\ssl\ because of a previous program I made)

    open FILE, $file or die $!;
    chomp(my @lines = <FILE>);
    close($file);

    foreach my $line (@lines)
    {
        my $ip = gethostbyname($line);
		if(!defined $ip)
		{
			next;
		}
		else
		{
			my $name = inet_ntoa($ip);
			my $ip_wan = $name;
			my @cijfers = split(/\./, $ip_wan);
			my $rev_ip = $cijfers[3].".".$cijfers[2].".".$cijfers[1].".".$cijfers[0];
			push(@rev_ip, $rev_ip);
			push(@dns_nm, $line);
		}
    }
    return (\@rev_ip, \@dns_nm);
  
}

sub items
{
    my $file = "C:\\SSL\\links.txt"; #In here same as above, the location of the links.txt file for me C:\ssl\ (ps, see double slashes).

    open FILE, $file or die $!;
    my @lines = <FILE>;
    close($file);
    return ($#lines);
}
sub w_leeg
{
    my $file = "C:\\Blacklist\\test.txt"; #the location where the empty blacklist file will be (temporary) stored.
    open F3, ">$file" or die $!;
	print F3 "";
	close F3;
}

sub check_ip($)
{
    my $bl_ip = $_[0];
    my $file = "C:\\Blacklist\\test.txt"; #the location where the full blacklist file will be (temporary) stored.
    my @providers = qw/.b.barracudacentral.org .zen.spamhaus.org .spam.spamrats.com .bl.spamcop.net/; # add qualified names only !
    my $found = 0;
    foreach my $q (@providers)
    {
        my $comm = $bl_ip.$q;
		&w_leeg();
        my @arr = `nslookup $comm`;
		open F1, ">>$file" or die $!;
		print F1 @arr;
		close F1;
		sleep 1;
		open F2, $file or die $!;
		my @narr = <F2>;
		close F2;
		foreach my $str (@narr)
		{
			if ($str =~ (/(127.\d{1,3}\.\d{1,3}\.\d{1,3})/))
			{
				$found +=1;
			}
			else
			{
				$found +=0; 
			}
		}
    } 
    return ($found);
}

sub real_ip($)
{
    my $ip = $_[0];
    my $name = $ip;
	my $ip_wan = $name;
	my @cijfers = split(/\./, $ip_wan);
	my $rev_ip = $cijfers[3].".".$cijfers[2].".".$cijfers[1].".".$cijfers[0];
	return ($rev_ip);
}

my $total = &items();
$total = $total-=1;

my ($g1,$g2) = &rev_dns_ip();

my(@first) = @$g1;
my(@second) = @$g2;

my ($naar, $van, $onderwerp, $bericht, $host);
my $zend = "uit.telenet.be"; #change this one for your ougoing server of your ISP.
$van = "blacklists\@netflow-it.com"; #Fancy mail, pick anything you like.
$naar = "user\@dom.com"; #add recipients
my $smtp = Net::SMTP->new("$zend", Timeout => 50);
my $verb = $smtp->domain;

$smtp->mail($van);
$smtp->to($naar);
$smtp->data();
$smtp->datasend("From: $van\n");
$smtp->datasend("To: $naar\n");
$smtp->datasend("Subject: Blacklist Check Klanten\n"); #Change everything Behind Subject: 
$smtp->datasend("Priority: Urgent\n");
$smtp->datasend("\n");
$smtp->datasend("Beste,\n\nHieronder de bedrijven die op een blacklist staan:\n\n"); #This is just a string with text, change it accordingly
for(my $i=0; $i<=$total;$i++)
{
    my $waarde =0;
	my $waarde2 = 0;
    $waarde = check_ip($first[$i]);
	$waarde2 = real_ip($first[$i]);
	print "MY IP:".$waarde2."\n";
    if($waarde>0)
    {
        $smtp->datasend($second[$i]. " : ". $waarde2. " blacklists: ". $waarde."\n");
    }
}
$smtp->datasend("\nControleer de Blacklists op: http://mxtoolbox.com/blacklist.aspx\n");
$smtp->datasend("\nSteeds tot uw dienst.\n\nMet vriendelijke groet,\n\nAlex Meys");
$smtp->dataend();
$smtp->quit;
&w_leeg(); #empty out temporary cache file don't change
print "\n\n...Cleaning up, thanks for using me, goodbye!\n"; #just to keep accidental viewers happy :-)