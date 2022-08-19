#! /bin/bash
# This script should be run inside the docker host machine 
# Outputs:
# - This script will clone required files for corresponding xxx_build.sh file 
mkdir -p tflite_2.8/tensorflow_src 
cd tflite_2.8/tensorflow_src
if [ ! -d tensorflow  ];then
    git clone --depth 1 --single-branch -b tidl-j7-2.8 https://github.com/TexasInstruments/tensorflow.git
    cd tensorflow
    git checkout  tidl-j7-2.8
    cd -
else 
    cd tensorflow
    git checkout  tidl-j7-2.8
    # git clean -fdx
    cd -
fi



