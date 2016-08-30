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
        setNewArtist(); # ask user input, artist, number of songs
    }
    getResponse(); # get lyrics, sort words, print results
}

# get lyrics of each song, sort words and print results
sub getResponse{
    getLyrics();
    sortResults();
}

# ask for user input / artist and number of songs
sub setNewArtist{
    getUserInputArtist(); # ask for artist name
    initRequest("http://search.azlyrics.com/search.php?q=$artist"); # search for artist
    getArtistUrl(); # get his profile url on azlyrics.com
    initRequest($artisturl); 
    getSongsUrl(); # get his songs' urls
    getUserInput(); # ask for number of songs to analyze
}

# manage -u -f cli arguments
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

# request url to get html code
sub initRequest{
    my $URL=$_[0];
    my $request = HTTP::Request->new(GET => $URL);
    my $response = $browser->request($request);
    my $contents = $response->content();
    @lines = split('\n', $contents);
}

# ask user to provide an artist as input
sub getUserInputArtist{
    print "[-] Give me a well known artist...\n";
    while (($artist=<STDIN>) !~ /\w/){
        print "[-] How about a name:\n";
    };
}

# get url of artist provided by user
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

# ask user to provide number of songs to analyze
sub getUserInput{
    print "[-] What are the most and least common words on $artist 's songs...\n";
    print "[-] How many songs of $artist should we try? No more than $#urls!\n";
    # ask for number < available songs
    while (($numberofsongs=<STDIN>) !~ /\d/ || $numberofsongs>$#urls){
        print "[-] How about a number, no more than $#urls:\n";
    };
}

# get urls of songs user requested
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
    # set in random order the urls list
    @urls = shuffle(@urls);
}

# TODO if -f cli argv is used
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

# get lyrics of each song
sub getLyrics{
    my $count = 0;
    print "\n";
    foreach (@urls){
        print "[URL_$count]: $_\n";
        initRequest($_);
        my $lyrics=0;
        foreach (@lines){
            # lyrics start here
            if($_=~/<!-- Usage of azlyrics.com content by any third-party lyrics provider is prohibited by our licensing agreement\. Sorry about that\. -->/){
                $lyrics=1;
            # lyrics end here
            }elsif($_=~/<!-- MxM banner -->/){
                $lyrics=0;
            }
            if($lyrics==1){
                # skip lines that include singer's name. Example: [Shakira:]
                if( $_ =~ /[(.*:*)]/ ){
                    next;
                }
                # count appearance of each word
                $seen{$_}++ for split /\W+/;
            }
        }
        last if ++$count > $numberofsongs-1;
    }
}

# sort words and print results
sub sortResults {
    my @noWords=('you','and','br','the'); #do not iclude these words in results
    my $boolean;
    my $count = 0;
    
    print "\n[-] Most used words: \n";
    # sort words in descending order
    for (sort {$seen{$b} <=> $seen{$a} || lc($a) cmp lc($b) || $a  cmp  $b} keys %seen){
        my $boolean=0;
        next unless /\w/; #skip any non-word characters
        next if /^[a-zA-Z]{1,2}$/; #skip words of 1 or 2 letters
        # skip the noWords
        for (my $i=0 ; $i<=$#noWords ; $i++){
            my $regex=qr/$noWords[$i]/i;
            if($_=~$regex){
                $boolean=1;
                last;
            }
        }
        next if($boolean == 1);
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9; # print only 10 results
    }
    $count = 0;
    
    print "\n[-] Least used words: \n";
    # sort words in ascending order
    for (sort { $seen{$a} <=> $seen{$b} || length($a) le length($b)} keys %seen){
        next unless /\w/; #skip any non-word characters
        next if /^[a-zA-Z]{1,2}$/; #skip words of 1 or 2 letters
        printf "%-10s   found... %d times\n", $_, $seen{$_};
        last if ++$count > 9; # print only 10 results
    }

    my $size = keys %seen;
    if(exists $argvs{'-u'} || exists $argvs{'-f'}){
        printf "\n[-] Unique words found: %d\n", $size;
    }else{
        printf "\n[-] Unique words used on $artist 's songs: %d\n", $size;
    }
}

