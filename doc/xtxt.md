
Extended Text File Specification 1.0
------------------------------------

- The extended text file format specification describes extensions to the
  traditional text file format that allow for an easier implementation,
  composition, and delivery of non-trivial file formats whilst retaining all
  the benefits of the long tradition of using text as the swiss knife
  and lingua franca of digital computer systems.

- mime type:  xtext/plain
- file extension: .xtxt  (in legacy OSes such as CPM/DOS/Windows 3.1: .xtx)
- file formats other than text/plain MAY also have multiple streams if 
  application designers so choose. It's conceivable that an application
  designer could want to produce and/or consume xtext/html xtext/rtf xtext/xml
  content for example. 

- Can allow for multiple streams
- Extends UTF-8 text files, an utf-8 text file is identical to a one-stream multiplexed text file
- Can be easily interpreted by any ext editors that don't want to implement the full spec, 
  discarding the extra streams
- Two different serialisation formats:  
    - multiplexed line by line (useful for enriched text without inline markup)
    - multiplexed stream by stream (useful for text and binary assets such as pictures)
- NO assumption MUST be made about presentation
    - can be used by a text editor as a regular text file if only one text stream is present
    - can be used by a generic text editor with each parallel stream in
      its own view stream. The traditional ui for hexadecimal editors usually has two 
      separate views, but both operate on the same streams. We propose that 
    - 
- Many applications beyond those that need trivial one-stream plain text files will be enabled.
    - For example:  multiple level json editing, csv data with master/detail views, 
      html that allows for parallel styling, comments, and javascript

Future work: 
------------
  - Enable for non-text streams to be multiplexed. 
  - In HTML: This may be needed by applications such as HTML, so that inline images 
  don't need to be encoded as src="data:" in base64. A different image source type 
  could be provided to access parallel binary data streams.
  - In multipart encoded emails: No need for email-specific decoding. An email could
  always be xtext/plain, with parallel rich text streams, and additional streams
  for image assets.
  - Simple binary data formats: tree or outline and graph-like data structures can
  be defined as the linkage of various streams. For example, a theoretical multiplexed 
  xtext/graphviz graph file format with a parallel stram representing the graph's
  adjacency matrix.
  - In 2.0, extend the specification to define standard schemata and 
  extended conventions to link streams in non-parallel structures.

  - Define conventions for GUI desktop clipboard formats and GUI controls that
  can produce and accept multiplexed text when copying and pasting.
  This alone could go a long way towards creating simple editors with multiplxed
  text functionality)

Coordinate work with
--------------------
- vim, emacs
- sublimetext, ultraedit, notepad++
- gnome gedit, kde kate
- any other popular FOSS or freeware editors?
- windows notepad, mac editor (really?)

Success criteria:
-----------------
In five years from now, most popular editors should implement at least one of:

--- tier 1 (full support)
    can read, display, edit multipla plain text streams,
    provides hooks/apis/interfaces for third parties to 
    develop their own substream editors and viewers.

--- tier 2 
    can read, display, edit multiple plain text streams,
    attach and organise binary streams

--- tier 3 
    can read, display, edit multiple plain text streams

--- tier 4 
    can read, display, and preserve or discard extended streams

--- tier 5 (trivial, almost unsupported)
    can read, display one stream, can only discard extended streams

As part of the Extended Text Specification 1.0 reference implementations
will be provided

xtxtkit - will include
----------------------
Written in clean ANSI c99 with minimal dependencies

- muxt      - assemble mtxt from simple files
- demuxt    - disassemble mtxt into simple files   
- muxcat    - view contents of mtxt 
- muxed     - a simple tier 3 mtxt editor

Roadmap
-------
Ideas to provide more complex implementations, 
ideally in C, C++, Java, Go, Rust, Ruby, Python, Javascript:

- muxvi     - a vi-like editor with multiplexed text support
- muxpad    - A QT and/or GTK based portable GUI editor
- muxdiff   - displays differences between mtxt files 

Muxnix tools
------------
Unix / GNU-like tools but muxed:
- muxtail, muxhead, muxsort, muxcut, muxniq, muxless, muxsed

Other suggested ideas:
----------------------
- muxhex    - muxed hexadecimal editor
- muxline   - muxed outline editor
- muxtodo   - muxed to-do list
- muxgv     - muxed graphviz editor 
- muxml     - muxed xml and html editor
- muxlog    - muxed log viewer
- muxgit    - muxed git


- = not implemented yet
* = implemented
+ = incomplete implementation

Starting with Ruby:
```
               muxt   demuxt   muxcat   muxed
               -------------------------------
C                -       -        -       -
C++              -       -        -       -
Pascal           -       -        -       -
Java             -       -        -       -
Go               -       -        -       -
Rust             -       -        -       -
Ruby             *       *        *       -
Python           -       -        -       -
Javascript       -       -        -       -
```

```
               muxvi  muxpad   muxdiff  muxnix
               -------------------------------
C                -       -        -       -
C++              -       -        -       -
Pascal           -       -        -       -
Java             -       -        -       -
Go               -       -        -       -
Rust             -       -        -       -
Ruby             -       -        -       -
Python           -       -        -       -
Javascript       -       -        -       -
```
