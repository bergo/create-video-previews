# Video preview

This bash scripts generate a preview version of a video as a small video sequence from the original video for a whole directory and generates a metadata json of all files in the folder.

## converts.sh

Generate a video squence using small sequences, generates a thumbnail from the middle of the original video and generates a metadata json with file refences and video length.

It supports only *.mp4 files right now.

    Usage: ./convert.sh [options] <video_file>

    Options:
    -f, --force              Force the creation of a new preview.
    -n, --scenes NUMBER      Set the number of scenes (default 10).
    -l, --length SECONDS     Set the length of each scene in seconds (default 5).
    -w, --width  MAX_WIDTH   Maximum width of the preview (default: 1280)
    -d, --height MAX_HEIGHT  Maximum height of the preview (default: 720)
    -a, --use_audio          Set to keep audio in the preview (default: remove audio)
    -h, --help               Display this help message and exit.
    <video_file>             The input file to process

## createIndex.sh

The bash scripts generates all preview files for a directory and creates a summary metadata file `combined_index.json` at the end.

    Usage: ./createIndex.sh <directory_path>

The variables for the generation can be adjusted at the beginning of the script.
