#creak_batch
This repo lets you run creak detection, from covarep, unsupervised on
a folder of your choice. The inputs are specified in creak_batch.sh and elsewhere.

You need:
- MATLAB (2014b+)
- python 2.7.x
- covarep, cloned (from github) into this folder
- praat 5.4.08+ on the path
- ffmpeg 2.6.2+
- bash

To run it, adjust the arguments in creak_batch.sh and either invoke it directly or set it as a cron job
Take care that only one copy runs at once.
