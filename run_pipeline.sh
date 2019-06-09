#!/usr/bin/bash

set -e
# input param 
# $1: sequence name
# $2: whether the video is upper body only (false by default, enable by -f)
seqName=$1
upperBody=$2

# Assume that you already have a video in $dataDir/(seqName)/(seqName).mp4 
dataDir=./data/
# Git clone openpose to ../openpose and compile with cmake
openposeDir=../openpose/

# convert to absolute path
MTCDir=$(readlink -f .)
dataDir=$(readlink -f $dataDir)
openposeDir=$(readlink -f $openposeDir)

if [ ! -f $dataDir/$seqName/calib.json ]; then
	echo "Camera intrinsics not specified, use default."
	cp -v POF/calib.json $dataDir/$seqName
fi

# use ffmpeg to extract image frames
cd $dataDir/$seqName
if [ ! -d raw_image ]; then
	mkdir raw_image
	ffmpeg -i $seqName.mp4 raw_image/${seqName}_%08d.png
fi

# run OpenPose on image frames
if [ ! -d openpose_result ]; then
	mkdir openpose_result
	cd $openposeDir
	./build/examples/openpose/openpose.bin --face --hand --image_dir $dataDir/$seqName/raw_image --write_json $dataDir/$seqName/openpose_result --render_pose 0 --display 0 -model_pose BODY_25 --number_people_max 1
fi

# merge openpose results into a single file
cd $MTCDir
numFrame=$(ls $dataDir/$seqName/openpose_result/$seqName_* | wc -l)
python3 POF/collect_openpose.py -n $seqName -r $dataDir/$seqName -c $numFrame

# run POF generation code
cd POF
python3 save_total_sequence.py -s $seqName -p $dataDir/$seqName --end-index 10 $upperBody
