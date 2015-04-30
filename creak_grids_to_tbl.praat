# This is a somewhat fragile utility script for transforming
# the results of do_creak_detection.m (a bunch of TGs)
# into one master table, output to the Info window
# the TextGrids must be names so that the timestamp in milliseconds
# is in the filename like this: _TIME.TextGrid

form Combine creak detection info into table
	comment Where are the TextGrids from the detection process?
	sentence small_tg_dir
endform

tbl = Create Table with column names: "tbl", 0, "start end"

Create Strings as file list: "small_tg_list", "'small_tg_dir$'/*.TextGrid"
tg_list = selected("Strings")

prevrow_start = -1
prevrow_end = -1

n_tgs = Get number of strings
for tg_i from 1 to n_tgs
	select tg_list
	this_tg$ = Get string: tg_i
	Read from file: "'small_tg_dir$'/'this_tg$'"
	small_tg	= selected("TextGrid")
	offset_ms$ = replace_regex$(this_tg$, "(^.*_)([0-9]+)(\.TextGrid)" , "\2", 0)
	offset_ms = number(offset_ms$)
	
	n_ints = Get number of intervals: 1
	for int_i from 1 to n_ints
		select small_tg
		int_label$ = Get label of interval: 1, int_i
		if int_label$ == "creak"
			intervalstart = Get start point: 1, int_i
			intervalend = Get end point: 1, int_i
            
            if intervalstart > prevrow_end
                select tbl
                Append row
                nrow = Get number of rows
                Set numeric value: nrow, "start", intervalstart
                Set numeric value: nrow, "end", intervalend
                
                prevrow_start = intervalstart
                prevrow_end = intervalend
            else
                select tbl
                nrow = Get number of rows
                Set numeric value: nrow, "end", intervalend
                prevrow_end = intervalend
            endif	
		endif
	endfor

	select small_tg
	Remove
endfor
select tg_list
Remove

select tbl
List: 0
