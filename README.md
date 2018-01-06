# Extended Text 1.0

The Extended Text format specification is a simple extension to
the traditional text/plain family of file formats.
The typical file extension for extended text files is .xtxt
and the proposed mime type is text/extended.

## Why

The reason for the existence of extended text files is to 
accomodate the needs of a number of file formats that can
benefit from text files that encapsulate multiple streams
of text, or put another way, multiplexed text.

## What

A typical case of an extended text file with multiplexed
streams could be a subtitles text file with more than
one language.  

## How
For example, you could have an extended
text file with three multiplexed streams of text like:

```
# Stream 1 | Stream 2   | Stream 3
# English  | #French    | Spanish
Hello      | Allo       | Hola
```
(Please note that this is not a plain text file.
The pipe characters are only for visualisation purposes.
A multiplexed file reader would only read text lines 
from each stream separately)

Another possible example is a rich text format with content 
separate from formatting and style like:
```
# Stream 1                        | # Stream 2
With freedom and justice for all  | [justice] bold
```
Could render the text as:

With freedom and **justice** for all

