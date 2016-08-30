# Lyrics-Crawler
Most / Least common words of your favorite artists' lyrics

**Author: olezt**

### Description

Find out the most and least common words that your favorite -or not- artists use in their lyrics.<br>
Songs are used in random sequence each time.<br>

See below for possible cli Arguments.<br>

Written entirely in Perl.<br>

Lyrics are obtained by www.azlyrics.com. Only for educational purposes.<br>
Keep in mind that using great number for songs to analyze may cause a ban ip. If it happen,you can restart your router. :laughing:

### Features

1. Analyze songs of specific artist
2. Analyze songs specified in file
3. Analyze song specified by cli argument
4. Print results both on cli and txt report file

### Cli Arguments
Name   |   Description   |   Example
------------ | ------------- | -------------
-u 	  |  Set url of a specific song to analyze | -u http://www.azlyrics.com/lyrics/2pac/meagainsttheworld.html
-f   |  Set a file with songs' urls as input | -f songs.txt

### How to use

Open cmd and execute ```perl lyricsCrawler.pl```<br>
  i.Specify a well known artist - He/She must be available on www.azlyrics.com<br>
  ii.Specify number of songs you want to analyze and enjoy the results<br>

<b>OR</b><br> 

Use one of the cli arguments

### Printscreen

<img src="screenShot.png" height="450"/>

### Requirements

1. Perl 5.8.0
