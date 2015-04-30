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
			intervalstart = offset_ms / 1000 + intervalstart
			intervalend = offset_ms / 1000 + intervalend
            
		# check start and end against tbl
		# is start in another interval?
		select tbl
		nrows = Get number of rows
		result = -1
		for row_i from 1 to nrows
			start = Get value: row_i, "start"
			end = Get value: row_i, "end"
			if start < intervalstart and end > intervalstart
				result = row_i
			endif
		endfor
		if result <> -1
			row_end = Get value: result, "end"
			if intervalend > row_end
				Set numeric value: nrow, "end", intervalend
			endif
		else
			# is end in another interval
			select tbl
			nrows = Get number of rows
			result = -1
			for row_i from 1 to nrows
				start = Get value: row_i, "start"
				end = Get value: row_i, "end"
				if start < intervalend and end > intervalend
					result = row_i
				endif
			endfor
			if result <> -1
				row_start = Get value: result, "start"
				if intervalstart < row_start
					Set numeric value: nrow, "start", intervalstart
				endif
			else
				# normal execution
				select tbl
				Append row
				nrow = Get number of rows
				Set numeric value: nrow, "start", intervalstart
				Set numeric value: nrow, "end", intervalend
			endif
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
