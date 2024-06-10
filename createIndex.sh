#!/bin/bash

# variables for the preview creation
video_width=1280
video_height=720
scene_length=1.1
num_scenes=12
force="" # use -f to force the creation of a new preview
remove_audio="" # by default remove audio
target_folder=""

usage() {
  echo
  echo "Create preview and index file for each video in the folder and a combined index for the whole folder."
  echo
  echo "Usage: $0 [options] <video_directory_path>"
  echo
  echo "Options:"
  echo "  -f, --force              Force the creation of a new preview."
  echo "  -o, --folder FOLDER      Set the target folder (default is current dir)."
  echo "  -n, --scenes NUMBER      Set the number of scenes (default 10)."
  echo "  -l, --length SECONDS     Set the length of each scene in seconds (default 5)."
  echo "  -w, --width  MAX_WIDTH   Maximum width of the preview (default: 1280)"
  echo "  -d, --height MAX_HEIGHT  Maximum height of the preview (default: 720)"
  echo "  -a, --use_audio          Set to keep audio in the preview (default: remove audio)"
  echo "  -h, --help               Display this help message and exit."
  echo "  <video_directory_path>   The input video directory to process"
  exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
      -f|--force)
        force="-f"
        ;;
      -o|--folder)
        target_folder="$2" ; shift
        ;;
      -n|--scenes)
        num_scenes=$2 ; shift
        ;;
      -l|--length)
        scene_length=$2 ; shift
        ;;
      -w|--width)
        video_width="$2" ; shift
        ;;
      -d|--height)
        video_height="$2" ; shift
        ;;
      -a|--use_audio)
        remove_audio="-a"
        ;;
      -h|--help)
        usage
        ;;
      --) shift; break ;;  # End of options
      -*|--*=)  # Unsupported flags
          echo "Error: Unsupported flag $1" >&2
          usage
          ;;
      *) break ;;  # End of options, start of positional arguments
    esac
  echo $1
  shift

done

# Check if the correct number of arguments is given
#if [ "$#" -ne 1 ]; then
if [ -z "$#" ]; then
  echo "Usage: $0 <directory_path>"
  exit 1
fi
directory="$1"

# Check if the directory exists
if [ ! -d "$directory" ]; then
  echo "The directory '$directory' does not exist."
  exit
fi

# The work directory containing all files
workDirectory=$(pwd)
echo "Work directory: $workDirectory"
echo "File directory: $directory"

cd "$directory" || exit 1


# this converts and generates all preview and meta files from original files
for file in *.mp4; do
    if [[ $file = *"_preview.mp4" ]]; then
        continue
    fi
    # Ensure that it's a file
    if [ -f "$file" ]; then
        echo "Processing $file"
        "$workDirectory"/convert.sh -o "$target_folder" -w $video_width -d $video_height -l $scene_length -n $num_scenes $force $remove_audio "$file"
    fi
done


# combine all JSON files in a directory into a single JSON file.

# The output JSON file
outputFile="${target_folder}combined_index.json"

output_json_file="$outputFile"
# Start of the JSON array
echo "{ \"files\": [" > "$output_json_file"

# Initialize a flag to handle commas between elements
first=true

# Loop through the json files in the directory
for json_file in ${target_folder}*_meta.json; do
    if [ "$first" = true ]; then
        first=false
    else
        # Add a comma before each element except the first one
        echo "," >> "$output_json_file"
    fi

    # Extract the field and write it to the output json file
    echo "$(cat "$json_file")" >> "$output_json_file"
done

# End of the JSON array
echo "] }" >> "$output_json_file"
jq . "$output_json_file" > "pretty_$output" && mv "pretty_$output" "$output_json_file"

echo "Combined JSON created: $outputFile"