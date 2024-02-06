#!/bin/bash

# variables for the preview creation
video_width=640
video_height=360
scene_length=1.1
num_scenes=12
force="-f" # use -f to force the creation of a new preview

# Check if the correct number of arguments is given
if [ "$#" -ne 1 ]; then
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
        "$workDirectory"/convert.sh -w $video_width -d $video_height -l $scene_length -n $num_scenes $force "$file"
    fi
done


# combine all JSON files in a directory into a single JSON file.

# The output JSON file
outputFile="combined_index.json"

output_json_file="$outputFile"
# Start of the JSON array
echo "{ \"files\": [" > "$output_json_file"

# Initialize a flag to handle commas between elements
first=true

# Loop through the json files in the directory
for json_file in *_meta.json; do
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