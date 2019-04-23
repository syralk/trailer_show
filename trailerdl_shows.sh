#!/bin/bash

#################################
#            Config             #
#################################

#Search this paths
PATHS=( "/sharedfolders/share/filme" "path2" "path3")

#Your Themoviedb API
API=

#Language Code
LANGUAGE=en

#Custom path to store the log files. Uncomment this line and change the path. By default the working directory is going to be used.
LOGPATH="/sharedfolders/share"

#################################

#Functions
downloadTrailer(){
        
	DL=$(youtube-dl   -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 "https://www.youtube.com/watch?v=$ID" -o "$DIR/trailers/$FILENAME-trailer.%(ext)s" --restrict-filenames)

		log "$DL"

        if [ -z "$(echo "$DL" | grep "100.0%")" ]; then
                missing ""
                missing "Error: Downloading failed - $FILENAME - $DIR - TheMovideDB: https://www.themoviedb.org/tv/$TMDBID - YouTube: https://www.youtube.com/watch?v=$ID"
                missing "------------------"
                missing "$DL"
                missing "------------------"
                missing ""
        else
                #Update file modification date
                touch "$DIR/trailers/$FILENAME-trailer.mp4"
        fi
}

log(){
        echo "$1" |& tee -a "$LOGPATH/trailerdl.log"
}

missing(){
        echo "$1" |& tee -a "$LOGPATH/trailerdl-error.log" &>/dev/null
}

#################################

#Delete old logs
rm "$LOGPATH/trailerdl.log" &>/dev/null
rm "$LOGPATH/trailerdl-error.log" &>/dev/null

#Use manually provided language code (optional)
if ! [ -z "$1" ]; then
        LANGUAGE="$1"
fi

if [ -z "$LOGPATH" ]; then
        LOGPATH=$(pwd)
fi

#Walk defined paths and search for tvs without existing local trailer
for i in "${PATHS[@]}"
do
	

        find "$i" -mindepth 1 -maxdepth 1 -type d '!' -exec sh -c 'ls -1 "{}" | egrep -i -q "trailer\.(mp4|avi|mkv)$"' ';' -print | while read DIR
        do
		
			FILENAME=$(ls "$DIR" | egrep '\.nfo$' | sed s/".nfo"//g)
						
			if [ ! -d "$DIR/trailers" ]; then
					
					
					if [ -f "$DIR/$FILENAME.nfo" ]; then

							#Get Themoviedb ID from NFO
							TVDBID=$(awk -F "[><]" '/tvdbid/{print $3}' "$DIR/$FILENAME.nfo" | awk -F'[ ]' '{print $1}')
							
							
							JSON_IMDB=($(curl $PROXY -s "https://api.themoviedb.org/3/find/$TVDBID?api_key=$API&external_source=tvdb_id" | jq -r '.tv_results[] | .id'))
							TMDBID="${JSON_IMDB[0]}"
							
						
							log ""
							log "tv Path: $DIR"
							log "TVDB: $TVDBID"
							log "TMDB: $TMDBID"
							log "Processing file: $FILENAME.nfo"

							if ! [ -z "$TMDBID" ]; then

									log "Themoviedb: https://www.themoviedb.org/tv/$TMDBID"

									#Get trailer YouTube ID from themoviedb.org
									JSON=($(curl  -s "http://api.themoviedb.org/3/tv/$TMDBID/videos?api_key=$API" | jq -r '.results[] | select(.type=="Trailer") | .key'))
									ID="${JSON[0]}"

									if ! [ -z "$ID" ]; then
											#Start download
											log "YouTube: https://www.youtube.com/watch?v=$ID"
											downloadTrailer

									else
											log "YouTube: n/a"
											missing "Error: Missing YouTube ID - $FILENAME - $DIR - TheMovideDB: https://www.themoviedb.org/tv/$TMDBID"

									fi

							else
									log "Themoviedb: n/a"
									missing "Error: Missing Themoviedb ID - $FILENAME - $DIR"
							fi

					fi
			fi
        done
done
