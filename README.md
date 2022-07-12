# Squash compound words in CHAT.

Perl script to identify compound words in CHAT files and squash them
into single words, in place, e.g. `ice+cream` to `icecream`.

Handles replacement words as in `[: ice+cream]` and `[:: ice+cream]`.

Usage:

```
$ split-compound-words.pl file.cha ...
```
