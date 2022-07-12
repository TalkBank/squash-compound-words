#!/usr/bin/perl -wn0777i

# Parse CHAT enough to identify main tiers (including continued lines)
# and extract words and split compound words that have +.

use warnings;
use strict;
use autodie;
use utf8;
use open qw/:std :encoding(UTF-8)/;

my @chunks = split /\n(?=[\@\*\%]|$)/;
for my $chunk (@chunks) {
    # Ignore main tier header.
    # Optimization since most of the time no + at all.
    if (my ($header, $content) = $chunk =~ /\A(\*[^:]+:\t)(.+)/) {
        if ($content =~ /\+/) {
            # TODO What about compounds in annotations?
            # *CHI:   wai4+yu3 [*] [= wai+yu] .

            # Remember to reject whitespace when identifying words.
            # Keep possible prefix &+.
            my $newContent = $content;
            $newContent =~ s/((?:&|&\-|&\+|0)?)
                          (
                               (?:
                                   \(
                                   [^-:0-9\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\+\s]
                               |
                                   [^-\(\)\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\+\s]
                               )

                               (?:
                                   [^\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\s]*

                                   [^\x{0015}\x{21D7}\x{2197}\x{2192}\x{2198}\x{21D8}\x{221E}\x{2261}\x{0001}\x{0002}\x{0003}\x{0004}\x{2308}\x{230A}\x{2309}\x{230B}\x{201C}\x{201D}\x{3014}\x{3015}\x{2039}\x{203A}\ &;!?\.,\x22<>{}=|*`\\%\[\]\s]
                               )?
                         )/$1 . splitWord($2)/xge;
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

# Replace compound + character in a word with space.
#
# Note: this changes the meaning of any attached annotations
# because now the annotations will only apply to the
# final new word, not the whole original compound.
#
# Similarly, if there was a form marker, it only stays
# with the final new word.
#
# Ignore + in form marker content.
sub splitWord {
    my ($word) = @_;
    if ($word =~ /\+/) {
        if (my ($base, $marker) = $word =~ /\A([^\@]*)(\@.*)?\Z/) {
            my $newBase = $base;
            my $numReplaced = $newBase =~ tr/+/ /;
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
