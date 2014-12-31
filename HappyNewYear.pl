#!/usr/bin/perl

use strict;
use warnings;

use utf8;
binmode STDOUT,":utf8";
binmode STDIN,":utf8";

use Net::Twitter;
use AnyEvent::Twitter::Stream;
use XML::Simple;
use HTTP::Date;
use Time::Local 'timelocal';

my $cv = AE::cv;

my $xml_ref = XMLin('./settings.xml');

print "来年は何年？";
my $year = <STDIN>;
chomp $year;
my $target_epoch = timelocal(0,0,0,1,0,$year-1900);


our $nt = Net::Twitter->new(

	consumer_key => $xml_ref->{consumer_key},
	consumer_secret => $xml_ref->{consumer_secret},
	access_token => $xml_ref->{access_token},
	access_token_secret => $xml_ref->{access_token_secret},
	ssl => 1,

);

my $ats = AnyEvent::Twitter::Stream->new(

	consumer_key => $xml_ref->{consumer_key},
	consumer_secret=> $xml_ref->{consumer_secret},
	token => $xml_ref->{access_token},
	token_secret => $xml_ref->{access_token_secret},
	method => "userstream",
	on_tweet => sub {

		 my $tweet = shift;
		 unless(defined($tweet->{text})){return};
		 my $text = $tweet->{text};
		 my $screen_name = $tweet->{user}{screen_name};

		 print $tweet->{text}."\n";

		 $text =~ s/明/あけ/g;
		 $text =~ s/御座/ござ/g;
		 $text = s/居ます/います/g;

		
		if(defined(&timer($tweet)) && $text =~ /あけ(|まして)おめ(|でとうございます)(|！)/){

			$nt->update("\@$screen_name あけ$1おめ$2$3 http://fono.jp/HNY.JPG");

		}

		return;
	 

	}
);
$cv->recv;
exit;


sub timer {

	my $tweet = shift;

	my $created_at = $tweet->{created_at};
	$created_at =~ s/\+0000//g;
	my $epoch_second = str2time($created_at) + 3600*9;

	print "$epoch_second $target_epoch\n";
	if($epoch_second >= $target_epoch){
		
		return 0;	
	}
	return undef;

}

