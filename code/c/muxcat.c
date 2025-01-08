#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include <unistd.h>

#define NSM 0xFE // Next Stream Marker
#define NFM 0xFD // Next Frame Marker
#define NCM 0xFC // Next Chunk Marker
#define BUFFER_SIZE 1024
#define MAX_STREAMS 128
#define MAX_FRAMES 1024
#define COLUMN_SIZE 20

typedef struct {
    char **lines;
    size_t line_count;
    size_t max_width;
} Stream;

Stream streams[MAX_STREAMS];
size_t stream_count = 0;
size_t longest_stream = 0;

void initialize_stream(Stream *stream) {
    stream->lines = malloc(sizeof(char *) * MAX_FRAMES);
    stream->line_count = 0;
    stream->max_width = 0;
}

void add_line_to_stream(Stream *stream, const char *line) {
    size_t len = strlen(line);
    stream->lines[stream->line_count] = malloc(len + 1);
    strcpy(stream->lines[stream->line_count], line);
    stream->line_count++;
    if (len > stream->max_width) {
        stream->max_width = len;
    }
}

void free_stream(Stream *stream) {
    for (size_t i = 0; i < stream->line_count; i++) {
        free(stream->lines[i]);
    }
    free(stream->lines);
}

void display_streams(bool show_line_numbers, size_t specific_line, int stream_index, size_t column_width) {
    for (size_t line_no = 0; line_no < longest_stream; line_no++) {
        if (specific_line > 0 && specific_line != line_no + 1) {
            continue;
        }

        if (show_line_numbers) {
            printf("%04zu ", line_no + 1);
        }

        for (size_t i = 0; i < stream_count; i++) {
            if (stream_index >= 0 && stream_index != i) {
                continue;
            }

            const char *line = line_no < streams[i].line_count ? streams[i].lines[line_no] : "";
            printf("%-*s", (int)column_width, line);
        }

        printf("\n");
    }
}

int main(int argc, char *argv[]) {
    bool show_line_numbers = true;
    int stream_index = -1;
    int column_width = COLUMN_SIZE;
    bool treat_as_header = false;
    size_t specific_line = 0;

    int opt;
    while ((opt = getopt(argc, argv, "ns:w:hl:")) != -1) {
        switch (opt) {
        case 'n':
            show_line_numbers = true;
            break;
        case 's':
            stream_index = atoi(optarg);
            break;
        case 'w':
            column_width = atoi(optarg);
            break;
        case 'h':
            treat_as_header = true;
            break;
        case 'l':
            specific_line = atoi(optarg);
            break;
        default:
            fprintf(stderr, "Usage: muxcat [-n] [-s INDEX] [-w WIDTH] [-h] [-l LINE] <file>\n");
            exit(EXIT_FAILURE);
        }
    }

    if (optind >= argc) {
        fprintf(stderr, "Error: No input file specified.\n");
        return 1;
    }

    const char *filename = argv[optind];
    FILE *file = fopen(filename, "rb");
    if (!file) {
        fprintf(stderr, "Error: Could not open file %s\n", filename);
        return 1;
    }

    uint8_t buffer[BUFFER_SIZE];
    size_t bytes_read;
    size_t idx = 0;
    size_t current_stream = 0;
    size_t frame_no = 0;
    uint8_t last_byte = 0; // Tracks the last byte of the previous chunk

    initialize_stream(&streams[current_stream]);

    while ((bytes_read = fread(buffer, 1, BUFFER_SIZE, file)) > 0) {
        size_t start_idx = 0;

        // Handle boundary marker spanning chunks
        if (last_byte == 0xFF) {
            switch (buffer[0]) {
            case NSM:
                current_stream++;
                if (current_stream >= MAX_STREAMS) {
                    fprintf(stderr, "Error: Too many streams\n");
                    fclose(file);
                    return 1;
                }
                initialize_stream(&streams[current_stream]);
                break;

            case NFM:
                frame_no++;
                break;

            case NCM:
                break;

            default:
                fprintf(stderr, "Error: Invalid marker 0x%02X at chunk boundary\n", buffer[0]);
                fclose(file);
                return 1;
            }
            start_idx = 1; // Skip the already processed marker byte
        }

        for (size_t i = start_idx; i < bytes_read; i++) {
            if (buffer[i] == 0xFF) {
                if (i + 1 >= bytes_read) {
                    last_byte = buffer[i]; // Save last byte for next chunk
                    break;
                }

                switch (buffer[i + 1]) {
                case NSM:
                    current_stream++;
                    if (current_stream >= MAX_STREAMS) {
                        fprintf(stderr, "Error: Too many streams\n");
                        fclose(file);
                        return 1;
                    }
                    initialize_stream(&streams[current_stream]);
                    break;

                case NFM:
                    frame_no++;
                    break;

                case NCM:
                    break;

                default:
                    fprintf(stderr, "Error: Invalid marker 0x%02X at position %zu\n", buffer[i + 1], i);
                    fclose(file);
                    return 1;
                }

                i++; // Skip marker byte
            } else {
                char line[BUFFER_SIZE] = {0};
                size_t line_idx = 0;

                while (i < bytes_read && buffer[i] != 0xFF && line_idx < BUFFER_SIZE - 1) {
                    line[line_idx++] = buffer[i++];
                }

                line[line_idx] = '\0';
                add_line_to_stream(&streams[current_stream], line);
                longest_stream = streams[current_stream].line_count > longest_stream ? streams[current_stream].line_count : longest_stream;
                i--; // Reprocess non-marker byte
            }
        }

        last_byte = buffer[bytes_read - 1]; // Save the last byte of the current chunk
    }

    fclose(file);

    display_streams(show_line_numbers, specific_line, stream_index, column_width);

    for (size_t i = 0; i <= current_stream; i++) {
        free_stream(&streams[i]);
    }

    return 0;
}
