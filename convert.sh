#!/bin/bash

# Default values
force=0
num_scenes=10
scene_length=2
max_width=1280
max_height=720
remove_audio=1 # by default remove audio

usage() {
  echo "Usage: $0 [options] <video_file>"
  echo
  echo "Options:"
  echo "  -f, --force              Force the creation of a new preview."
  echo "  -n, --scenes NUMBER      Set the number of scenes (default 10)."
  echo "  -l, --length SECONDS     Set the length of each scene in seconds (default 5)."
  echo "  -w, --width  MAX_WIDTH   Maximum width of the preview (default: 1280)"
  echo "  -d, --height MAX_HEIGHT  Maximum height of the preview (default: 720)"
  echo "  -a, --use_audio          Set to keep audio in the preview (default: remove audio)"
  echo "  -h, --help               Display this help message and exit."
  echo "  <video_file>             The input file to process"
  exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -f|--force)
      force=1
      ;;
    -n|--scenes)
      num_scenes=$2 ; shift
      ;;
    -l|--length)
      scene_length=$2 ; shift
      ;;
    -w|--width) 
      max_width="$2" ; shift
      ;;
    -d|--height) 
      max_height="$2" ; shift 
      ;;
    -a|--use_audio) 
      remove_audio=1
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
  shift
done

# Check if a video file was provided
#if [ $# -ne 1 ]; then
if [ -z "$#" ]; then
  echo "Error: Please provide a video file."
  # echo "Usage: $0 <video_file>"
  usage
fi

video_file="$1"
preview_file="${video_file%.*}_preview.mp4"
thumbnail_filename="${video_file%.*}.png"
meta_file="${video_file%.*}_meta.json"


if [ ! -f "$video_file" ]; then
    echo "Error: Input file does not exist."
    exit 1
fi

# Check if preview exists and act accordingly
if [ -f "$preview_file" ]; then
  if [ $force -eq 0 ]; then
    echo "Preview exists. Use -f or --force to overwrite."
    exit
  fi
  rm "$preview_file"
fi

# Prepare ffmpeg options for scaling
scale_option="-vf scale=$max_width:$max_height:force_original_aspect_ratio=decrease,pad=$max_width:$max_height:-1:-1:color=black"

# Prepare ffmpeg options for audio
if [ "$remove_audio" -eq 1 ]; then
    audio_option="-an"
else
    audio_option=""
fi


# Assign the video filename to a variable
input_video="$video_file"

# Output file name
output_video="$preview_file"

# Get the duration of the video in seconds
video_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_video")
echo "duration: $video_duration"

#total_frames=$(ffmpeg -i $input_video -v trace 2>&1 -hide_banner | grep -A 10 codec_type=0 | ack -o "(?<=sample_count = )\d+") 
#echo "total frames: $total_frames"

# Calculate the total number of frames in the video
#total_frames=$(ffprobe -v error  -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of default=noprint_wrappers=1:nokey=1 "$input_video")
# total_frames=134205
#echo "total frames: $total_frames"

# Determine the interval in seconds between the starting points of each scene (skipping the first 10% and last 10% of the video)
interval=$(( (${video_duration%.*} - (2 * 10)) / 9 ))
echo "interval: $interval"

# Initialize an empty file list
file_list=""


# Extract 10 scenes of 2 seconds each from the video
echo "Creating a video preview with $num_scenes scenes, each $scene_length seconds long."
for (( i=1; i<=$num_scenes; i++ )); do
    start_time=$(echo "scale=2; 0.1 * ${video_duration%.*} + ($i - 1) * $interval" | bc)
    clip="preview_clip_${i}.mp4"
    # Use ffmpeg to extract a 2-second clip from the video
    ffmpeg -ss "$start_time" -i "$input_video" -t "$scene_length" $scale_option $audio_option -c:v libx264 -preset fast -crf 28 "$clip" -loglevel error
    if [ -f "$video_file" ]; then
        file_list+="$clip|"
    fi
done

# Remove the trailing pipe from the file list
file_list=${file_list%|}

# Concatenate the clips using the concat demuxer
# the safe flag is required if your paths have special characters
ffmpeg -f concat -safe 0 -i <(for f in ${file_list//|/ }; do echo "file '$PWD/$f'"; done) -c copy "$output_video" -loglevel error

# Clean up the temporary clip files
for f in ${file_list//|/ }; do
    rm "$f"
done

echo "Preview generated as: $output_video"



# create a thumbnail
if [ -f "$thumbnail_filename" ]; then
  rm "$thumbnail_filename"
fi
middle_time=$(( (${video_duration%.*} / 2) | bc))
ffmpeg -ss "$middle_time" -i "$input_video" -vf "thumbnail,scale=$max_width:$max_height" -frames:v 1 "$thumbnail_filename" -loglevel error


# Create a JSON object using jq
rounded_duration=$(( (${video_duration%.*}) | bc))

json_content=$(jq -n \
                  --arg video_file "$input_video" \
                  --arg preview_output "$output_video" \
                  --arg thumbnail_output "$thumbnail_filename" \
                  --arg video_duration "$rounded_duration" \
                  '{
                      video_filename: $video_file,
                      preview_filename: $preview_output,
                      thumbnail_filename: $thumbnail_output,
                      duration: $video_duration
                   }')

# Save the JSON content to a file
echo "$json_content" > "$meta_file"