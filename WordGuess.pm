package Games::WordGuess;

use strict;
use vars qw(@ISA $VERSION @EXPORT_OK $MAX_GUESS $MIN_LENGTH $MAX_LENGTH);

require Exporter;
require AutoLoader;

$VERSION = '0.20';
@ISA = qw(Exporter AutoLoader);

@EXPORT_OK = qw($MIN_LENGTH $MAX_LENGTH);

$MAX_GUESS = 8;
$MIN_LENGTH = 5;
$MAX_LENGTH = 9;

my @words;

# constructor
sub new
{
    my ($class, $filename) = @_;
    my $self = {
                fn => $filename,
                words => \@words,
                score => 0,
                mystery => undef,
                in_progress => undef,
                chances => $MAX_GUESS,
                };
    bless($self, $class);
    $self->init_words();
    $self->init_mystery();
    return $self;
}

sub init_words
{
    my $self = shift;
    @{$self->{words}} = $self->{fn} ? _preprocess($self->{fn}) : qw(
        sementara kondisi ekonomi politik sulit sekali);
}

sub init_mystery
{
    my $self = shift;
    $self->{chances} = $MAX_GUESS;
    $self->init_words() if (@{$self->{words}} == 0);
    my $word_idx = rand(@{$self->{words}});
    $self->{mystery} = splice(@{$self->{words}}, $word_idx, 1);
    $self->{mystery} =~ tr/a-z/A-Z/;
    ($self->{in_progress} = $self->{mystery}) =~ tr/A-Z/*/;
}

sub get_score
{
    return shift->{score};
}

sub get_chances
{
    return shift->{chances};
}

sub in_progress
{
    return shift->{in_progress};
}
 
# main method, return undef if missed, return 0 if matched, return 1 if 
# finished:
sub process_guess
{
    my ($self, $char) = @_;
    return undef unless $char;
    $char = substr($char, 0, 1);
    $char = "\u$char";
    my $pos = $[;
    my $found = 0;
    while (($pos = index($self->{mystery}, $char, $pos)) >= $[)
    {
        last if (substr($self->{'in_progress'}, $pos, 1) eq $char);
        substr($self->{'in_progress'}, $pos, 1) = $char;
        $pos++;
        $found++;
    }
    if ($found)
    {
        return 0 if ($self->{'in_progress'} ne $self->{mystery});
        $self->{score} += $self->{chances} * 10 + 10;
        return 1;
    }
    else 
    {
        $self->{chances}--;
        return undef;
    }
}

# do plain interaction via STDOUT/STDIN

sub command_interface
{
    my $self = shift;
    my ($result, $in);

    for(;;)
    {
        do
        {
    printf("%-9s  Remaining chances: %d.  Your score is: %6d.  Next guess: ",
        $self->{'in_progress'}, $self->get_chances, $self->{score});    
        
            chomp($in = <STDIN>);

            if (defined($result = $self->process_guess($in)) && $result)
            {
                #next if ($result < 0);
                print "You win the word!\n";
                print "The word is: ", $self->get_answer(), "\n";
                print "Your score is: ", $self->{score}, "\n";
                return 1;
            }
        } while ($self->get_chances);
        print "You stupid idiot!\n";
        print "The word is: ", $self->get_answer(), "\n";
        return 0;
    }
}

sub get_answer
{
    my $self = shift;
    return $self->{mystery};
}

# utility to get words from a file - internal use only
sub _preprocess
{
    my $filename = shift;
    my (@w, $w, %w, @words, $l);
    local $/ = "";
    open (FN, "<$filename") or die "Can't open $filename.";
    while(<FN>)
    {
        s/-\n//g;
        tr/A-Z/a-z/;
        @w = split(/\W*\s+\W*/, $_);
    }
    
    %w = map{$_,1} @w;
        
    close FN;
    foreach $w(keys %w)
    {
        if ($w !~ /\W/ and ($l = length $w) > $MIN_LENGTH and 
            $l < $MAX_LENGTH)
        {
            push @words, $w;
        }
    }
    return @words;
}

1;
__END__


=head1 NAME

Games::WordGuess - a class for creating word-guessing game

=head1 SYNOPSIS

  use Games::WordGuess;

  $game = new Games::WordGuess;
  $game = new Games::WordGuess("/usr/games/lib/fortunes/startrek");  

=head1 DESCRIPTION

Games::WordGuess is a module for word-guessing game. 
Scoring is calculated from the number of chances left for each mystery word.

=head2 Constructor

Specify the full path to the file containing words to be played at the
C<new()> method, for example:

  $game = new Games::WordGuess("/usr/games/lib/fortunes/startrek");  

otherwise, C<Games::WordGuess> uses some internal Indonesian words as the
default.

=head2 Simple command line user interface

Look at examples/cmdln script on example of using C<command_interface()>.

=head2 process_guess()

This is the core method. Passed a character, C<process_guess> will return
undef if there's no matched character in the current mystery word. If it is
passed a previous matched character, it returns undef as well. On success,
it returns 0, or 1 if the mystery word has already revealed.

=head2 in_progress()

Returns the mystery word in current player's progress. Initially, after a 
C<Game::WordGuess> object is created, this will return the mystery word 
covered with asterisks. On each matched guess, the corresponding asterisk 
will be substituted by the real character.

=head2 get_chances()

Returns the remaining chances left for current player.

=head2 get_score()

Returns total score for current player.

=head2 init_mystery()

Provides a new mystery word to current player. Call to this method is required 
to continue the game after successful guess of one complete word.

=head1 HISTORY

=over 2

=item * August 16, 1999 - Version 0.20:

process_guess() now returns undef on missed guess. Added in_progress() method.
Added documentation, and a CGI script example using Apache::Session.

=item * July 1999 - Version 0.11:

Changes to command_interface(), as suggested by Steven
Haryanto <sh@hhh.indoglobal.com>.

=item * April 1999 - Publicly released, Version 0.10

=back

=head1 AUTHOR

Edwin Pratomo <B<ed.pratomo@computer.org>>

=head1 COPYRIGHT

Copyright (c) 1999 Edwin Pratomo <ed.pratomo@computer.org>.

All rights reserved. This is a free code; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
