## Internet-Draft

### Extended Text Format 1.0

**Document Name:** draft-ietf-xtxt-00

**Category:** Standards Track

**Abstract:**
The Extended Text Format (XTXT) defines a standardized text-based format that allows for multiplexed text streams within a single file. By introducing stream and frame markers to the UTF-8 text encoding, XTXT enables new applications such as multilingual subtitles, rich text with separated style layers, and structured data encoding. This document specifies the XTXT format, its markers, and considerations for implementation.

---

## Status of this Memo

This document is an Internet-Draft of the Internet Engineering Task Force (IETF), intended to describe a standard for adoption. Comments and discussion about this document should be addressed to the IETF mailing list at ietf@example.org.

---

## Table of Contents

1. Introduction  
2. Terminology  
3. Overview  
   3.1 Purpose  
   3.2 Design Principles  
4. Format Specification  
   4.1 File Structure  
   4.2 Control Markers  
   4.3 Examples  
5. Implementation Considerations  
6. Use Cases  
7. Future Work  
8. Security Considerations  
9. IANA Considerations  
10. References  

---

## 1. Introduction

The Extended Text Format (XTXT) is a text-based file format designed to handle multiplexed streams of text. It extends the UTF-8 standard ([RFC 3629](https://www.ietf.org/rfc/rfc3629.txt)) by introducing special control markers that separate streams and frames within a file. The primary goal of XTXT is to enable applications requiring multiple parallel text layers without sacrificing compatibility with traditional text tools.

### Problem Statement

Traditional text formats, such as plain text or UTF-8, are limited to a single stream of content. This restriction makes it challenging to encode related information, such as:

- Multilingual subtitles.  
- Rich text with separated formatting layers.  
- Structured data with parallel content streams.  

By introducing the concept of multiplexed text streams, XTXT addresses these limitations while preserving the simplicity and universality of text-based formats.

---

## 2. Terminology

**UTF-8:** A character encoding defined by RFC 3629.  
**Stream:** A sequence of text lines representing a distinct layer of content.  
**Frame:** A collection of lines from all streams, corresponding to a logical grouping (e.g., a subtitle frame).  
**NSM (Next Stream Marker):** A control marker separating streams within a frame.  
**NFM (Next Frame Marker):** A control marker separating frames.

---

## 3. Overview

### 3.1 Purpose

XTXT aims to:
- Extend UTF-8 to support multiple parallel streams within a single file.
- Enable interoperability with existing text-processing tools.
- Provide a foundation for applications in multilingual text, rich text processing, and structured data encoding.

### 3.2 Design Principles

1. **Backward Compatibility:** XTXT files are valid UTF-8 files. Non-XTXT-aware tools can process them as plain text, discarding extended features.  
2. **Minimalism:** The format introduces only two markers (NSM and NFM), keeping complexity low.  
3. **Extensibility:** Future versions may include support for binary streams or linked structures.  

---

## 4. Format Specification

### 4.1 File Structure

An XTXT file consists of:

1. An optional UTF-8 BOM (Byte Order Mark) for encoding identification.  
2. Lines of text organized into streams and frames, separated by:  
   - **NSM (Next Stream Marker):** `0xFF 0xFE`  
   - **NFM (Next Frame Marker):** `0xFF 0xFD`  

### 4.2 Control Markers

- **NSM (Next Stream Marker):** A two-byte sequence (`0xFF 0xFE`) marking the end of one stream and the beginning of another within the same frame.  
- **NFM (Next Frame Marker):** A two-byte sequence (`0xFF 0xFD`) marking the end of all streams in a frame and the start of a new frame.  

Markers are encoded as UTF-8 and occupy two bytes each.

### 4.3 Examples

#### Example 1: Multilingual Subtitles

```
Hello [NSM] Allo [NSM] Hola [NFM]
World [NSM] Monde [NSM] Mundo [NFM]
```

#### Example 2: Rich Text with Style Separation

```
With freedom and justice for all [NSM] [justice] bold [NFM]
```

Rendered Output:

> With freedom and **justice** for all

---

## 5. Implementation Considerations

1. **Encoding:** XTXT relies on UTF-8 encoding. Implementations must handle encoding errors gracefully.  
2. **Performance:** For large files, processing line-by-line or stream-by-stream is recommended to optimize memory usage.  
3. **Tooling:** Tools should support:  
   - Parsing XTXT markers.  
   - Extracting and editing individual streams.  

---

## 6. Use Cases

1. **Multilingual Subtitles:** Store subtitles in multiple languages within a single file.  
2. **Rich Text Processing:** Separate content from formatting or metadata layers.  
3. **Structured Data Encoding:** Encode parallel data streams for CSV-like or hierarchical data.  

---

## 7. Future Work

1. **Binary Streams:** Support for multiplexed binary data (e.g., images).  
2. **Non-Parallel Structures:** Linking streams hierarchically for graphs or outlines.  
3. **Clipboard Formats:** Standardize GUI clipboard interaction for XTXT.  

---

## 8. Security Considerations

XTXT introduces no new security risks beyond those inherent in text processing. Implementations must:
- Validate marker sequences to prevent malformed input.  
- Handle large files to avoid memory exhaustion attacks.  

---

## 9. IANA Considerations

This document requests the registration of a new MIME type, `text/extended`, to represent Extended Text (XTXT) files. Associated file extensions include `.xtxt` (preferred) and `.xtx` (optional for legacy systems).

### MIME Type Registration

- **Name:** `text/extended`  
- **Extensions:** `.xtxt`, `.xtx`  
- **Encoding:** UTF-8 by default; future versions may support other encodings.  
- **Fragment Identifier Syntax:** None (as of version 1.0).  
- **Description:** Multiplexed text file format for storing parallel text streams.  

### Justification

The `text/extended` MIME type allows systems and applications to distinguish XTXT files from other text formats and provides a foundation for future extensions.  

---

## 10. References

1. **RFC 3629:** UTF-8, a transformation format of ISO 10646.  
2. **Unicode Standard:** Version 14.0 or later.  

---

**Author:**  
haitch@duck.com
