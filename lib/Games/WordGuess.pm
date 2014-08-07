package Games::WordGuess;

our $DATE = '2014-08-07'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

use Module::List qw(list_modules);
use Module::Load;

sub new {
    my $class = shift;
    my %attrs = @_;

    # select and load default wordlist
    my $mods = list_modules("Games::Word::Wordlist::", {list_modules=>1});
    my @wls = map {s/.+:://; $_} keys %$mods;
    print "Available wordlists: ", join(", ", @wls), "\n";
    my $wl = $attrs{word_list};
    if (!$wl) {
        if (($ENV{LANG} // "") =~ /^id/ && "KBBI" ~~ @wls) {
            $wl = "KBBI";
        } else {
            $wl = $wls[rand @wls];
        }
    }
    die "Can't find module for wordlist '$wl'" unless $wl ~~ @wls;
    my $mod = "Games::Word::Wordlist::$wl";
    load $mod;
    print "Loaded wordlist from $mod\n";

    # select eligible words from the wordlist
    my @words;
    {
        my $wlobj = $mod->new;
        my $l1 = int($attrs{min_len} // 5);
        my $l2 = int($attrs{max_len} // 5);
        @words = $wlobj->words_like(qr/\A[a-z]{$l1,$l2}\z/);
        die "Can't find any eligible words in wordlist '$wl'"
            unless @words;
        $attrs{_wlobj} = $wlobj;
        $attrs{words} = \@words;
    }

    $attrs{num_words} //= 10;

    bless \%attrs, $class;
}

sub run {
    my $self = shift;

    $self->{num_correct} = 0;
    $self->{score} = 0;

    for my $i (1..$self->{num_words}) {
        print "\nWord $i/$self->{num_words}:\n";
        my ($is_correct, $score) = $self->ask_word;
        $self->{num_correct}++ if $is_correct;
        $self->{score} += $score;
    }
    $self->show_final_score;
}

sub ask_word {
    my $self = shift;

    my $words = $self->{words};
    my $word  = $words->[rand @$words];
    #say "D:word=$word";
    my $wlen  = length($word);

    my $max_guesses = $self->{max_guesses} // $wlen;

    my $i = 0;
    my $gletters = substr($word, 0, 1) . ("*" x ($wlen-1));
    $self->show_diff($word, $gletters);
    while ($i < $max_guesses) {
        $i++;
        print $i < $max_guesses ? "Your guess ($i/$max_guesses)? " :
            "Your last guess? ";
        chomp(my $guess = <STDIN>);
        unless ($self->{_wlobj}->is_word($guess)) {
            $self->show_diff($word, $gletters);
            print "Sorry, not a word! ";
            $i--;
            next;
        }
        unless (length($guess) eq $wlen) {
            $self->show_diff($word, $gletters);
            print "Sorry, not a $wlen-letter word! ";
            $i--;
            next;
        }
        if (lc($guess) eq $word) {
            my $score = ($wlen*(1-($i-1)/$max_guesses))*20;
            print "Correct ($score points)!\n";
            return (1, $score);
        }
        my $gletters_new = $self->show_diff($word, $guess);
        $gletters = $gletters_new
            if $self->get_num_chars($gletters, '*') >
                $self->get_num_chars($gletters_new, '*');
    }
    print "Chances used up. The correct word is: $word\n";
    return (0, 0);
}

sub get_num_chars {
    my ($self, $s, $char) = @_;
    my $orig = $s;
    $s =~ s/\Q$char//ig;
    length($orig) - length($s);
}

sub show_diff {
    my ($self, $word, $guess) = @_;
    my $gletters = "";
    #print "D:show_diff: $word vs $guess\n";
    $guess = lc($guess);
    my $word2 = $word;

    # what letters are in the incorrect position
    for my $i (0..(length($word)-1)) {
        my $l = substr($word, $i, 1);
        $word2 =~ s/\Q$l// if length($guess)>$i && substr($guess, $i, 1) eq $l;
     }

    for my $i (0..(length($word)-1)) {
        my $l  = substr($word, $i, 1);
        my $gl = length($guess) > $i ? substr($guess, $i, 1) : "";
        if ($l eq $gl) {
            print "$l ";
            $gletters .= $l;
        } elsif (length($gl) && $word2 =~ s/\Q$gl//) {
            print "$gl*";
            $gletters .= "*";
        } else {
            print "_ ";
            $gletters .= "*";
        }
        print " ";
    }
    #print "\n";
    $gletters;
}

sub show_final_score {
    my $self = shift;

    print "\n";
    printf "Number of words guessed correctly: %d/%d\n",
        $self->{num_correct}, $self->{num_words};
    printf "Final score: %.0f\n", $self->{score};
}

1;
# ABSTRACT: Word guess game

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::WordGuess - Word guess game

=head1 VERSION

This document describes version 0.02 of Games::WordGuess (from Perl distribution Games-WordGuess), released on 2014-08-07.

=head1 SYNOPSIS

 % wordguess

=for Pod::Coverage ^(.+)$

=head1 SEE ALSO

L<wordguess>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Games-WordGuess>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Games-WordGuess>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-WordGuess>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
