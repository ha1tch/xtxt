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
The extended text format is based on the utf-8 standard
(https://www.ietf.org/rfc/rfc3629.txt)

The extended text format adds a couple of control codes
to utf-8, in order to provide the ability of reading and writing 
files with parallel lines of text. 

In multiplexed audio and video formats you have the concept
of streams, with parallel content which may be called "frames".
In this extended text specification we are not interleaving
characters similar to the way some video formats interleave
their content. The main purpose of the extended text format
is to be able to retrieve parallel lines of utf-8 text.

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
A multiplexed file reader would only read parallel text lines 
from each stream separately)

Another possible example is a rich text format with content 
separate from formatting and style like:
```
# Stream 1                        | # Stream 2
With freedom and justice for all  | [justice] bold
```
Could render the text as:

With freedom and **justice** for all

