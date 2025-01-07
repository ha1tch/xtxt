package main

import (
	"fmt"
	"io"
	"os"
)

func countFramesInXtxt(filePath string) (int, error) {
	const markerHigh = 0xFF
	const markerLow = 0xFD

	file, err := os.Open(filePath)
	if err != nil {
		return 0, fmt.Errorf("could not open file: %w", err)
	}
	defer file.Close()

	frameCount := 0
	buffer := make([]byte, 1024)
	var prevByte byte = 0

	for {
		n, err := file.Read(buffer)
		if err != nil {
			if err == io.EOF {
				break
			}
			return 0, fmt.Errorf("error reading file: %w", err)
		}

		for i := 0; i < n; i++ {
			currentByte := buffer[i]
			if prevByte == markerHigh && currentByte == markerLow {
				frameCount++
			}
			prevByte = currentByte
		}
	}

	return frameCount, nil
}

func main() {
	filePath := "input.xtxt"
	frames, err := countFramesInXtxt(filePath)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Printf("Total frames: %d\n", frames)
}
