#include <stdio.h>
#include <stdlib.h>

#define BUFFER_SIZE 1024
#define MARKER_HIGH 0xFF
#define MARKER_LOW  0xFD

int count_frames_in_xtxt(const char *file_path) {
    FILE *file = fopen(file_path, "rb");
    if (file == NULL) {
        perror("Error opening file");
        return -1;
    }

    unsigned char buffer[BUFFER_SIZE];
    int frame_count = 0;
    size_t bytes_read;
    unsigned char prev_byte = 0;

    while ((bytes_read = fread(buffer, 1, BUFFER_SIZE, file)) > 0) {
        for (size_t i = 0; i < bytes_read; i++) {
            unsigned char current_byte = buffer[i];
            if (prev_byte == MARKER_HIGH && current_byte == MARKER_LOW) {
                frame_count++;
            }
            prev_byte = current_byte;
        }
    }

    if (ferror(file)) {
        perror("Error reading file");
        fclose(file);
        return -1;
    }

    fclose(file);
    return frame_count;
}

int main() {
    const char *file_path = "input.xtxt";

    int frame_count = count_frames_in_xtxt(file_path);
    if (frame_count >= 0) {
        printf("Total frames: %d\n", frame_count);
    } else {
        printf("Failed to count frames.\n");
    }

    return 0;
}
