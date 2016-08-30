#!/usr/local/bin/perl

# Author @olezt

use strict;
use warnings;

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTML::LinkExtor;
use List::Util 'shuffle';

my $browser = LWP::UserAgent->new();
   $browser->timeout(10);
my @lines;
my @urls;
my $numberofsongs;
my $artist;
my %seen;
my $artisturl;
my %argvs;

main();
exit 1;

sub main{
    if( $#ARGV>0 && $#ARGV<2){
        manageArgvs();
    }elsif($#ARGV>=2){
        print "You can provide only one argument";
        exit 1;
    }else{
        setNewArtist();
    }
    getResponse();
}

sub getResponse{
    getLyrics();
    sortResults();
}

sub setNewArtist{
    getUserInputArtist();
    initRequest("http://search.azlyrics.com/search.php?q=$artist");
    getArtistUrl();
    initRequest($artisturl);
    getSongsUrl();
    getUserInput();
}

sub manageArgvs{
    for(my $i=0 ; $i<$#ARGV ; $i=$i+2){
        $argvs{$ARGV[$i]} = $ARGV[$i+1];
    }
    if(exists $argvs{'-u'}){
        push(@urls, $argvs{'-u'});
        $numberofsongs=1;
    }elsif(exists $argvs{'-f'}){
        ifArgvf();
    }else{
        print "Argument is not valid.\n";
        exit 1;
    }
}


sub initRequest{
    my $URL=$_[0];
    my $request = HTTP::Request->new(GET => $URL);
    my $response = $browser->request($request);
    # if ($response->is_error()) {printf "%s\n", $response->status_line;}
    my $contents = $response->content();
    @lines = split('\n', $contents);
}

sub getUserInputArtist{
    print "[-] Give me a well known artist...\n";
    while (($artist=<STDIN>) !~ /\w/){
        print "[-] How about a name:\n";
    };
}

sub getArtistUrl{
    foreach (@lines){
        if ($_ =~ /1\..* <a href="(http:\/\/www\.azlyrics\.com\/.*\/.*\.html)" target="_blank">(.*|\s)/){
            $artisturl=$1;
            $artisturl=~/http:\/\/www\.azlyrics\.com\/.*\/(.*)\.html/;
            $artist=$1;
            last;
        }
    }
}

sub getUserInput{
    print "[-] What are the most and least common words on $artist 's songs...\n";
    print "[-] How many songs of $artist should we try? No more than $#urls!\n";

    while (($numberofsongs=<STDIN>) !~ /\d/ || $numberofsongs>$#urls){
        print "[-] How about a number, no more than $#urls:\n";
    };
    
}

sub getSongsUrl{
    foreach (@lines){
        if ($_ =~ /.*?(href="\.\.)(\/lyrics\/$artist\/.*?html)/ | /.*?(h:\.\.")(\/lyrics\/$artist\/.*?html)/){
            push(@urls, "http://www.azlyrics.com$2"); 
        }
    }
    if(!$urls[0]){
        print "[-] Sorry this artist does not exist in azlyrics website.\n[-] Try someone else\n";
        setNewArtist();
    }
@urls = shuffle(@urls);
}

sub ifArgvf{
    open (FILE, "$argvs{'-f'}") or die "Error opening the file $argvs{'-f'}\n";
    while (<FILE>){
        push(@urls, $_) for split /\s+/; 
    }
    $numberofsongs=@urls;    
    if(!$urls[0]){
        print "Something went wrong.";
    }
    close (FILE);
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
    my @noWords=('you','and','br','the');
    my $boolean;
    my $count = 0;
    print "\n[-] Most used words: \n";
  
        for (sort {$seen{$b} <=> $seen{$a} || lc($a) cmp lc($b) || $a  cmp  $b} keys %seen){
        my $boolean=0;
        next unless /\w/;
        next if /^[a-zA-Z]{1,2}$/;
        for (my $i=0 ; $i<=$#noWords ; $i++){
            my $regex=qr/$noWords[$i]/i;
            if($_=~$regex){
                $boolean=1;
                last;
            }
        }
        next if($boolean == 1);
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9;
    }
    $count = 0;
    print "\n[-] Least used words: \n";
    for (sort { $seen{$a} <=> $seen{$b} || length($a) le length($b)} keys %seen){
        next unless /\w/;
        next if /^[a-zA-Z]{1,2}$/;
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9;
    }

    print "\n";
    my $size = keys %seen;
    if(exists $argvs{'-u'} || exists $argvs{'-f'}){
        printf "[-] Unique words found: %d\n", $size;
    }else{
        printf "[-] Unique words used on $artist 's songs: %d\n", $size;
    }
}

