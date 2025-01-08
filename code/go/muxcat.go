package main

import (
	"bytes"
	//	"encoding/hex"
	//	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

// Constants
const (
	NSM               = "FFFE" // Next Stream Marker
	NFM               = "FFFD" // Next Frame Marker
	NCM               = "FFFC" // Next Chunk Marker
	DefaultColumnSize = 20
)

// Options structure to hold command-line arguments
type Options struct {
	ShowLineNumbers bool
	StreamIndex     int
	ColumnWidth     int
	Header          bool
	SpecificLine    int
}

// Marker type
const (
	MarkerNSM = 0xFE
	MarkerNFM = 0xFD
	MarkerNCM = 0xFC
)

func main() {
	// Parse command-line arguments
	options := Options{}
	flag.BoolVar(&options.ShowLineNumbers, "n", true, "Display line numbers")
	flag.IntVar(&options.StreamIndex, "s", -1, "Display only the specified stream index")
	flag.IntVar(&options.ColumnWidth, "w", DefaultColumnSize, "Specify column width")
	flag.BoolVar(&options.Header, "head", false, "Treat the first line as a header")
	flag.IntVar(&options.SpecificLine, "l", 0, "Display only the specified line")
	flag.Parse()

	if flag.NArg() < 1 {
		fmt.Fprintln(os.Stderr, "Usage: muxcat [options] <file>")
		os.Exit(1)
	}

	filePath := flag.Arg(0)
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: Could not read file %s\n", filePath)
		os.Exit(1)
	}

	streams, streamWidths, err := parseXTXT(content)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing XTXT file: %v\n", err)
		os.Exit(1)
	}

	displayStreams(streams, streamWidths, options)
}

func parseXTXT(content []byte) ([][]string, []int, error) {
	var streams [][]string
	var streamWidths []int

	var currentStream []string
	var currentFrame []string
	var streamWidth int

	idx := 0
	for idx < len(content) {
		if content[idx] == 0xFF {
			switch content[idx+1] {
			case MarkerNSM:
				if currentStream == nil {
					currentStream = []string{}
				}

				if len(currentFrame) > 0 {
					currentStream = append(currentStream, currentFrame...)
					streamWidth = max(streamWidth, findMaxLength(currentFrame))
					currentFrame = nil
				}

				streams = append(streams, currentStream)
				streamWidths = append(streamWidths, streamWidth)
				currentStream = nil
				streamWidth = 0

			case MarkerNFM:
				currentStream = append(currentStream, currentFrame...)
				currentFrame = nil

			case MarkerNCM:
				// End of chunk handling (optional, can be customized)
			default:
				return nil, nil, fmt.Errorf("invalid marker 0x%02X at position %d", content[idx+1], idx)
			}

			idx += 2
		} else {
			// Regular content
			line := readUntil(content, idx, 0xFF)
			currentFrame = append(currentFrame, string(line))
			idx += len(line)
		}
	}

	if currentStream != nil {
		streams = append(streams, currentStream)
		streamWidths = append(streamWidths, streamWidth)
	}

	return streams, streamWidths, nil
}

func displayStreams(streams [][]string, streamWidths []int, opts Options) {
	longestStream := findMaxStreamLength(streams)

	for lineNo := 0; lineNo < longestStream; lineNo++ {
		if opts.SpecificLine > 0 && lineNo+1 != opts.SpecificLine {
			continue
		}

		outputLine := ""
		for streamIdx, stream := range streams {
			if opts.StreamIndex >= 0 && opts.StreamIndex != streamIdx {
				continue
			}

			columnWidth := opts.ColumnWidth
			if lineNo < len(stream) {
				outputLine += padRight(stream[lineNo], columnWidth)
			} else {
				outputLine += strings.Repeat(" ", columnWidth)
			}
		}

		if opts.ShowLineNumbers {
			fmt.Printf("%3d %s\n", lineNo+1, outputLine)
		} else {
			fmt.Println(outputLine)
		}
	}
}

func readUntil(content []byte, start int, stop byte) []byte {
	end := bytes.IndexByte(content[start:], stop)
	if end == -1 {
		return content[start:]
	}
	return content[start : start+end]
}

func padRight(str string, length int) string {
	if len(str) >= length {
		return str[:length]
	}
	return str + strings.Repeat(" ", length-len(str))
}

func findMaxLength(lines []string) int {
	maxLength := 0
	for _, line := range lines {
		if len(line) > maxLength {
			maxLength = len(line)
		}
	}
	return maxLength
}

func findMaxStreamLength(streams [][]string) int {
	maxLength := 0
	for _, stream := range streams {
		if len(stream) > maxLength {
			maxLength = len(stream)
		}
	}
	return maxLength
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
