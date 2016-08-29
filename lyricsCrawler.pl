#!/usr/local/bin/perl

# Tests for site crawler / db creator

use strict;
use warnings;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTML::LinkExtor;

my $browser = LWP::UserAgent->new();
$browser->timeout(10);
my @lines;
my @urls;
my $numberofsongs;
my $artist;
my %seen;
my $count = 0;

initRequest('http://www.azlyrics.com/19/2pac.html');
getUserInput();
getSongsUrl();
getLyrics();
sortResults();
1;

sub initRequest{
    my $URL=$_[0];
    my $request = HTTP::Request->new(GET => $URL);
    my $response = $browser->request($request);
    if ($response->is_error()) {printf "%s\n", $response->status_line;}
    my $contents = $response->content();
    @lines = split('\n', $contents);
}

sub getUserInput{
    print "[-] What are the most and least common words on 2Pac songs...\n";
    print "[-] How many songs of Tupac should we try?\n";

    while (($numberofsongs=<STDIN>) !~ /\d/){
        print "[-] How about a number:\n";
    };
}

sub getSongsUrl{
    foreach (@lines){
        if ($_ =~ /.*?(href="\.\.)(\/lyrics\/2pac\/.*?html)/ | /.*?(h:\.\.")(\/lyrics\/2pac\/.*?html)/){
            push(@urls, "http://www.azlyrics.com$2"); 
        }
    }
}

sub getLyrics{
    my $count = 0;
    print "\n";
    foreach (@urls){
        print "[URL_$count]: $_\n";
        initRequest($_);
        my $lyrics=0;
        foreach (@lines){
            if($_=~/<!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement\. Sorry about that\. -->/){
                $lyrics=1;
            }elsif($_=~/<!-- MxM banner -->/){
                $lyrics=0;
            }
            if($lyrics==1){
                $seen{$_}++ for split /\W+/;
            }
        }
        last if ++$count > $numberofsongs-1;
    }
}

sub sortResults {
    my $count = 0;
    print "\n[-] Most used words: \n";
    
    for (sort {$seen{$b} <=> $seen{$a} || lc($a) cmp lc($b) || $a  cmp  $b} keys %seen){
        next unless /\w/;
        #next if /(br)|[a-zA-Z]{1,1}/;
        next if /(br)|(i)/;
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9;
    }
    $count = 0;
    print "\n[-] Least used words: \n";
    for (sort { $seen{$a} <=> $seen{$b} } keys %seen){
        next unless /\w/;
        #next if /(br)|[a-zA-Z]{1,1}/;
        next if /(br)|(i)/;
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9;
    }

    print "\n";
    my $size = keys %seen;
    printf "Total words used: %d\n", $size;
}