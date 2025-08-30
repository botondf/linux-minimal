#!/bin/bash

# Take a dir as arg, fall back to current dir if none given
#working_directory="$1"
# This is the completed Nicotine downloads dir
#cd "~/.local/share/nicotine/downloads"
working_directory="/home/botond/.local/share/nicotine/downloads"
cd "$working_directory"
#pwd
# Where the pretty new music directory should be. Cannot be empty
target_directory="/home/botond/music/sharing"

# try to make the new target dir
mkdir -p "$target_directory"

# Look for these exentions (in order of priority)
# flac most common so save time
extensions=("flac" "wav" "mp3")

# Temp array to hold results
declare -a results
declare -a hits_dirs

# Loop through directories from process substitution < <()
# handle spaces in dirs and prevent dont read \
while IFS= read -r dir; do
	# Iterate extensions we are looking for
	for ext in "${extensions[@]}"; do
		# Search for files only (-type f) in $dir (-maxdepth 1) ending with an extension from array (filename case insensitive)
		# Print and quit on first find
		result=$(find "$dir" -maxdepth 1 -type f -iname "*.$ext" -print -quit)
		# Check if file is non-empty, only then process metadata
		if [ -n "$result" ]; then
			# Append song file to array of results
			results+=("$result")
			# Append song path to array of hits
			hit_dirs+=("$dir")
			# Only need to add first file, this enough to make the folders
			break
		fi
	done
# Feed recursive output of find to while loop, that is all dirs in $directory
# (process substitution)

done < <(find "$working_directory" -type d)

# Process metadata for all collected files
for i in "${!results[@]}"; do
	song="${results[$i]}"
	dir="${hit_dirs[$i]}"
	# Extract FORMAT tags from the audio file comment. no wrappers, no keys, just the string we want
	artist="$(ffprobe -v error "$song" -of default=noprint_wrappers=1:nokey=1 -hide_banner -show_entries format_tags=artist)"
	album="$(ffprobe -v error "$song" -of default=noprint_wrappers=1:nokey=1 -hide_banner -show_entries format_tags=album)"
	year="$(ffprobe -v error "$song" -of default=noprint_wrappers=1:nokey=1 -hide_banner -show_entries format_tags=date)"
	# Print date only if there is one
	if [[ -z "$year" ]]; then
		printf "%s - %s (n.d.)\n" "$artist" "$album"
		mkdir -p "$target_directory/$artist/$album (n.d.)"
		mv -nu "$dir"/* "$target_directory/$artist/$album (n.d.)"
		# recursive, never overwrite, only overwrite if changed
		rmdir "$dir"

	else
		printf "%s - %s (%s)\n" "$artist" "$album" "$year"
		mkdir -p "$target_directory/$artist/$album ($year)"
		mv -nu "$dir"/* "$target_directory/$artist/$album ($year)"
		# recursive, never overwrite, only overwrite if changed
		rmdir "$dir"
	fi
done

nicotine -r

mpc update

## maybe a way to process some dates to just year. but need to check if YYYY-xx-xx (12char format)
#date -d 1993-01-01 +%Y
