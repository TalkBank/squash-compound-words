#!/usr/bin/perl -w0777i

# Parse CHAT enough to identify main tiers (including continued lines)
# and extract words and squash compound words that have +.

use warnings;
use strict;
use autodie;
use utf8;
use open qw/:std :encoding(UTF-8)/;

# $1: prefix
# $2: rest
my $wordRegex = qr/((?:&|&\-|&\+|0)?)
                          (
                               (?:
                                   \(
                                   [^-:0-9\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\+\t\n\/]
                               |
                                   [^-\(\)\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\+\t\n\/]
                               )

                               (?:
                                   [^\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\t\n]*

                                   [^\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\t\n]
                               )?
                         )/x;

while (<>) {
    my @chunks = split /\n(?=[\@\*\%]|$)/;
    for my $chunk (@chunks) {
        # Ignore main tier header.
        # Optimization since most of the time no + at all.
        if (my ($header, $content) = $chunk =~ /\A(\*[^:]+:\t)(.+)/s) {
            if ($content =~ /\+/) {
                # TODO What about compounds in annotations?
                # *CHI:   wai4+yu3 [*] [= wai+yu] .

                # Identify word-like tokens. Not exact because we are
                # not fully tokenizing. E.g. numbers in bullets get picked up.
                # But they don't affect the final outcome because of no +.
                #
                # Remember to reject tabs and newlines when identifying words.
                # Keep possible prefix &+.
                #
                # Disallow initial /.
                my $newContent = $content;
                $newContent =~ s/(\[[^\]]*\])|$wordRegex/squashContent($1, $2, $3)/ge;
                print $header, $newContent, "\n";
            }
            else {
                # Unchanged.
                print $chunk, "\n";
            }
        } else {
            # Unchanged.
            print $chunk, "\n";
        }
    }
}

sub squashContent {
    my ($bracketed, $wordPrefix, $wordRest) = @_;
    if (defined($bracketed)) {
        # Only look into replacements.
        if (my ($prefix, $content, $suffix) = $bracketed =~ /\A(\[:+\ *)([^\]]+)(\])\z/) {
            my $newContent = $content;
            $newContent =~ s/$wordRegex/$1 . squashWord($2)/ge;
            $prefix . $newContent . $suffix
        } else {
            # Unchanged.
            $bracketed
        }
    } else {
        # Word.
        $wordPrefix . squashWord($wordRest)
    }
}

# Squash compound + character in a word.
#
# Ignore + in form marker content.
sub squashWord {
    my ($word) = @_;
    if ($word =~ /\+/) {
        if (my ($base, $marker) = $word =~ /\A([^\@]*)(\@.*)?\z/) {
            my $newBase = $base;

            # Squash out +.
            my $numReplaced = $newBase =~ s/\+//g;
            if ($numReplaced > 0) {
                my $changedWord = defined($marker) ?
                        "$newBase$marker" :
                        $newBase;

                # For visible progress.
                 print STDERR "$ARGV: [$word] -> [$changedWord]\n";

                $changedWord
            }
            else {
                # Unchanged.
                $word
            }
        }
        else {
            die "Impossible match failure: $word\n";
        }
    }
    else {
        # Unchanged.
        $word
    }
}
