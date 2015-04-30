#!/bin/bash
#
# creak_batch.sh
#   Patrick Callier
#
# looks in AUDIO_DIR for wav files to work on, which have matching TSV transcripts
# in TRS_DIR (5-column format: spkr spkr start end txt)
# For those files that meet this criterion, and that also do not have matching results 
# table in RESULTS_DIR.
# Splits wav file into segments according to timings in transcript, name including
# start time in milliseconds, into a working folder
# runs do_creak_detection on working folder.
# A tsv with two columns, start and end, for each detected segment of creak
# is made from the results, and deposited in RESULTS_DIR
# and the working directory is cleared
# Only one instance of this should run at a time, so watch out.
# praat must be on the path

AUDIO_DIR="/media/sf_corpora/living_room/data/audio"
WORKING_DIR="${HOME}/tmp"
TRS_DIR="/media/sf_corpora/living_room/data/annotations"
RESULTS_DIR="/media/sf_creak_results"
SCRIPT_DIR=`cd $(dirname "${0}"); pwd`
errorlog="${SCRIPT_DIR}/errors.log"
echo "" > "$errorlog"


# loop over folders in data directory
for wav_file in "$AUDIO_DIR"/*.wav ; do
    file_code=$(echo $(basename $wav_file) | sed s/\.wav$//g)
    trs_file="$TRS_DIR"/${file_code}.txt
    if [ -f "$trs_file" ]; then
        result_file="$RESULTS_DIR"/${file_code}.txt
    	if [ ! -f "$result_file" ]; then
           # clear out working directory
            find "${WORKING_DIR}" -type f -name "*.wav" -exec rm -rf {} \;
            find "${WORKING_DIR}" -type f -name "*.TextGrid" -exec rm -rf {} \;
            rm -f "${WORKING_DIR}/creak_results.txt"

		echo "Beginning work on ${file_code}"

            # split audio (head -n 100 "$trs_file" |)
            sed 1d "$trs_file" | awk -F $'\t' '{ print $1 "\t" $3 "\t" $4 }' | while IFS=$'\t' read spkr start_sec end_sec ; do
		output_dur=$(echo "$end_sec - $start_sec" | bc)
		printf -v output_dur '%03f' "$output_dur"
                slice_name=${spkr}_$(python -c 'import math; print "{:d}".format(int(math.floor('$(echo "$start_sec" | bc )'*1000)))')
		#echo "${WORKING_DIR}/${slice_name}.wav"
                ffmpeg -nostdin -loglevel error -ss $start_sec -i "$wav_file" -t $output_dur -ar 16000 "${WORKING_DIR}/${slice_name}.wav"
            done

	    echo "Audio divided. Beginning creak detection on ${file_code}"
            # do creak detection
            matlab -nodisplay -nosplash -r "cd ${SCRIPT_DIR}/covarep; startup; cd ${SCRIPT_DIR}; do_creak_detection('${WORKING_DIR}'); exit" >> "$errorlog"
            if [ "$?" -ne 0 ]; then
                echo "Matlab had bad exit in ${file_code}" >> "$errorlog"
                find "${WORKING_DIR}" -type f -name "*.wav" -exec rm -rf {} \;
                find "${WORKING_DIR}" -type f -name "*.TextGrid" -exec rm -rf {} \;
                continue
            fi

            # compile results into a single table (with praat)
            praat "${SCRIPT_DIR}/creak_grids_to_tbl.praat" "${WORKING_DIR}" > "${WORKING_DIR}/creak_results.txt"
            mv "${WORKING_DIR}/creak_results.txt" "${result_file}"
            echo "Creak detection complete. Results at ${result_file}"             
 
	fi
	fi
done
