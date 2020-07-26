#!/bin/sh

###############################################################################
#
#   Script to download wallpapers from picture subreddits
#		Author: Andreas Hauser <ahauser31@hotmail.com>
#		Version: 1.0.0
#   Copyright (C) 2020  Andreas Hauser
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###############################################################################

# Default configuration values

# Folders for downloaded images and history file
FOLDER="$HOME/Pictures/wallpapers/reddit"
RECENT="$FOLDER/wallpaper.txt"

# Reddit configuration; sorting, subreddit to search and number of links to process
# possible values: hot, top or new
SORTBY="top"
# Some possibilities: earthporn, spaceporn, wallpaper
SUBREDDIT="wallpaper"
MAXLINKS="100"

# Image settings; minimum suitable dimensions and allowed aspect ratios
MINWIDTH="1920"
MINHEIGHT="1080"
# Image ratio must be between MINRATIO and MAXRATIO to be deemed suitable
# Ratios are multiplied by 1000 to avoid floating point arithmatic; default ratios 4/3 and 21/9
MINRATIO=$((4000/3))
MAXRATIO=$((21000/9))

# Tool settings; force download of a new image, shuffle results, verbose mode
SHUFFLE="true"
FORCE="false"
VERBOSE="false"

# Helper functions

# Try to extract the image dimensions from a string if present in the format \[numberxnumber\]
extract_dimensions()
{
		echo "$1" | grep -Eo "[\[\(]\s*[0-9]{3,4}x[0-9]{3,4}\s*[])]"
		# Alternative: sed -E 's|.*(\[[0-9]{3,4}x[0-9]{3,4}\]).*|\1|'
}

# Determine if the dimensions of the image are suitable for wallpaper usage
# Input: \[numberxnumber\]
suitable_dimensions()
{
		WIDTH="$(echo "$1" | sed -E 's|[^0-9]*([0-9]*)x.*|\1|')"
		HEIGHT="$(echo "$1" | sed -E 's|.*x([0-9]*)[^0-9]*|\1|')"
		#RATIO="$(echo "$WIDTH/$HEIGHT" | bc)"
		RATIO="${WIDTH}000"
		RATIO="$((RATIO / HEIGHT))"

		if [ "$WIDTH" -ge "$MINWIDTH" ] && [ "$HEIGHT" -ge "$MINHEIGHT" ] && [ "$RATIO" -ge "$MINRATIO" ] && [ "$RATIO" -le "$MAXRATIO" ]; then
				echo "true"
		else
			  echo "false"
		fi
}

# Getting filename from link
get_filename()
{
		echo "$1" | sed -E 's|.*/(.*\..*)"|\1|'
}

# Download file header to analyze it with ImageMagick
analyze_image()
{
		# Downloas first 16384 bytes of image to hopefully determine the dimensions
		CANDIDATE="$1"

		if [ "$VERBOSE" = "true" ]; then
				echo >&2 "Trying to determine size of picture \"$CANDIDATE\""
		fi

		if ! RES="$(curl -s -r 0-16384 -A "wallpaper-reddit sh script" "$CANDIDATE" | identify -format "[%wx%h]" -)"; then
				# No resolution found, return empty string
				echo ""
		else
				if [ "$VERBOSE" = "true" ]; then
						echo >&2 "Size dermined to $RES"
				fi

				# Return found resolution
				echo "$RES"
		fi
}

usage()
{
		echo "Usage: $0 [-f|-n|-v] [ -p OUTPUT PATH ] [ -s SORTBY ] [ -r SUBREDDIT ] [ -m MAXLINKS ] [ -e MINHEIGHT ] [ -w MINWIDTH ] [ -i MINRATIO ] [ -a MAXRATIO ]"
  	exit 2
}

get_ratio()
{
		VAL1="${1%%/*}000"
		VAL2="${1##*/}"
		echo $((VAL1/VAL2))
}

# Script starting point

# Check command line arguments
# Force, no shuffle, Path, Sort, subReddit, Maxlinks, hEight, Width, mInratio, mAxratio, Help
while getopts 'fnvp:s:r:m:e:w:i:a:h?' ARG
do
		case $ARG in
			f) FORCE="true" ;;
			n) SHUFFLE="false" ;;
			v) VERBOSE="true" ;;
			p) FOLDER="$OPTARG" ;;
			s) SORTBY="$OPTARG" ;;
			r) SUBREDDIT="$OPTARG" ;;
			m) MAXLINKS="$OPTARG" ;;
			e) MINHEIGHT="$OPTARG" ;;
			w) MINWIDTH="$OPTARG" ;;
			i) MINRATIO="$(get_ratio "$OPTARG")" ;;
			a) MAXRATIO="$(get_ratio "$OPTARG")" ;;
			h|?) usage ;;
		esac
done

# First, check if the target folder exists and create it if not
if [ ! -d "$FOLDER" ]; then
		mkdir -p "$FOLDER"
fi

# Check if today was already a run of the script, then just return current wallpaper
if [ "$FORCE" = "false" ] && [ -e "$RECENT" ]; then
		# Recent file exists, read in to compare date
		SAVEIFS=$IFS
		#IFS=$'\t' # Bashism
		IFS=$(echo t | tr t \\t)
		while read -r RECENTDATE RECENTFILE; do
			...
		done < "$RECENT"
		IFS=$SAVEIFS

		CURRENTDATE="$(date +%Y%m%d)"
		RECENTDATE="$(echo "$RECENTDATE" | sed 's|/||g')"
		
		# It is trivial to compare two dates if they are in the format YYYYMMDD
		if [ "$CURRENTDATE" -le "$RECENTDATE" ]; then
				# Just retun filename and exit
				if [ "$VERBOSE" = "true" ]; then
						echo "Already downloaded picture today, current picture is: \"$RECENTFILE\""
				else
						echo "$RECENTFILE"
				fi
				exit 0
		fi
fi

# Getting json file
URL="https://www.reddit.com/r/$SUBREDDIT/$SORTBY.json?limit=$MAXLINKS"
if [ "$VERBOSE" = "true" ]; then
		echo "Grabbing JSON file \"$URL\""
fi

LINKS=""

LINKS="$(curl -s -A "wallpaper-reddit sh script" "$URL" | jq '.data.children | .[] | .data.title, .data.url, .data.permalink' 2>/dev/null | \
	 (while read -r TITLE; do
					read -r REDDITURL
					read -r PERMALINK

					# Weed out non-images - look at extension first - Note: will still have quote mark at the end
					EXT="${REDDITURL##*.}"

					if [ "$EXT" != "jpg\"" ] && [ "$EXT" != "png\"" ] && [ "$EXT" != "jpeg\"" ]; then
							# Not directly an image, may be imgur or flickr
							if [ -z "${EXT##*imgur*}" ] ;then
									# If imgur, its assumed the image is a jpg and its at i.imgur.com
									REDDITURL="$(echo "$REDDITURL" | sed -e 's|imgur|i.imgur|' -e 's|"|.jpg"|2')"
							else
									# No solution for flickr, as the owner can disable download of the image and multiple sizes are possible
									continue
							fi
					fi

					if [ -n "$LINKS" ]; then
						LINKS="$LINKS\n"
					fi
					LINKS="$LINKS$TITLE\t$REDDITURL\t$PERMALINK"
		done && echo "$LINKS"))"

# Check for errors during parsing / downloading
if [ -z "$LINKS" ]; then
		if [ "$VERBOSE" = "true" ]; then
				echo "ERROR: Cannot download or parse \"$URL\". Please try again"
		fi

		exit 1
fi

# Shuffling results
if [ "$SHUFFLE" = true ]; then
		LINKS="$(echo "$LINKS" | shuf)"
fi

# Go through list of picture candidates to find a suitable one and download first suitable picture
echo "$LINKS" | while read -r LINE; do
		LINK="$(echo "$LINE" | awk -F"\t" '{print $2}')"
		FILENAME="$FOLDER/$(get_filename "$LINK")"

		# Check if file was already downloaded
		if [ -e "$FILENAME" ]; then
				# Skip this file
				if [ "$VERBOSE" = "true" ]; then
						echo "Picture \"$LINK\" was downloaded before, skipping"
				fi

				continue
		fi

		# Strip quote marks from link for downloading
		LINK="${LINK#\"}"
		LINK="${LINK%\"}"

		# Checking dimensions of images from the top of the list down until a fitting one is found
		# Easiest method is looking at the title, which often contains the image size
		# If not in the title, use ImageMagick identify to get the dimensions
		# shellcheck disable=SC1012
		TITLE="$(echo "$LINE" | awk -F"\t" '{print $1}')"
		DIM="$(extract_dimensions "$TITLE")"

		if [ -z "$DIM" ]; then
				# Dimension not found in title, need to download image header
				DIM="$(analyze_image "$LINK")"

				if [ -z "$DIM" ]; then
						# No valid dimensions returned, skip image
						if [ "$VERBOSE" = "true" ]; then
								echo "Dimensions of picture \"$LINK\" cannot be determined, skipping"
						fi

						continue
				fi
		fi

		# Check if image is suitable for use as wallpaper
		if [ "$(suitable_dimensions "$DIM")" = "false" ]; then
				# Image not suitable
				if [ "$VERBOSE" = "true" ]; then
						echo "Picture \"$LINK\" has unsuitable dimensions, skipping"
				fi

				continue
		fi

		# Downloading file...
		if [ "$VERBOSE" = "true" ]; then
				echo "Downloading file \"$LINK\""
		fi

		curl -s -A "wallpaper-reddit sh script" "$LINK" -o "$FILENAME"
		# Saving filename and date to history file
		printf '%s\t%s' "$(date +%Y/%m/%d)" "$FILENAME" > "$RECENT"

		if [ "$VERBOSE" = "true" ]; then
				echo "New picture: \"$FILENAME\""
		else
				# Echoing out downloaded file for other scripts / tools to process
				echo "$FILENAME"
		fi
		exit 0
done

# If this point is reached, the entire list of links did not contain a suitable image
if [ "$VERBOSE" = "true" ]; then
		echo "ERROR: No suitable image found. Please increase number of links or try another subreddit."
fi
exit 1
