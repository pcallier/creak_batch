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

AUDIO_DIR="audio"
WORKING_DIR=""
TRS_DIR="annotations"
RESULTS_DIR=""
SCRIPT_DIR=`cd $(dirname "${0}"); pwd`
errorlog="${SCRIPT_DIR}/errors.log"

# loop over folders in data directory
for wav_file in "$AUDIO_DIR"/*.wav ; do
    file_code = $(echo $(basename $wav_file) | sed s/\.wav$//g)
    trs_file = "$TRS_DIR"/${file_code}.txt
    if [ -f "$trs_file" ]; then
        result_file = "$RESULTS_DIR"/${file_code}.txt
    	if [ ! -f "result_file" ]; then
    		echo "Beginning work on ${file_code}"

            # split audio
            sed 1d "$trs_file" | awk -F $'\t' '{ print $1 "\t" $3 "\t" $4 }' | while IFS=$'\t' read spkr start_sec end_sec ; do
                output_dur = $(echo "$end_sec - $start_sec" | bc)
                slice_name = $spkr_$(python -c 'import math; print math.floor('$(echo "$start_sec" | bc )'*1000)')
                ffmpeg -ss $start_sec -i "$wav_file" -t $output_dur "${WORKING_DIR}${slice_name}.wav"
            done

            # do creak detection
			matlab -r "cd ${SCRIPT_DIR}/covarep; startup; cd ${SCRIPT_DIR}; do_creak_detection('${WORKING_DIR}'); exit" >> "$errorlog"
            if [ "$?" -ne 0 ]; then
                echo "Matlab had bad exit in ${file_code}" >> "$errorlog"
                find "${WORKING_DIR}" -type f -name "*.wav" -exec rm -rf {} \;
                find "${WORKING_DIR}" -type f -name "*.TextGrid" -exec rm -rf {} \;
                continue
            fi

            # delete wav files
            find "${WORKING_DIR}" -type f -name "*.wav" -exec rm -rf {} \;
            find "${WORKING_DIR}" -type f -name "*.TextGrid" -exec rm -rf {} \;
            
            # compile results into a single table (with praat)
            praat "${SCRIPT_DIR}/creak_grids_to_tbl.praat" "${WORKING_DIR}" > "${WORKING_DIR}/creak_results.txt"
            mv "${WORKING_DIR}/creak_results.txt" "${result_file}
            
            # clear out working directory
            find "${WORKING_DIR}" -type f -name "*.wav" -exec rm -rf {} \;
            find "${WORKING_DIR}" -type f -name "*.TextGrid" -exec rm -rf {} \;
            rm -f "${WORKING_DIR}/creak_results.txt"
		fi
	fi
done