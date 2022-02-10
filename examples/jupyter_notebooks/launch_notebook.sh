#!/usr/bin/env bash
skip_setup=0
skip_models_download=0

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    --skip_setup)
    skip_setup=1
    ;;
    --skip_models_download)
    skip_models_download=1
    ;;
    -h|--help)
    echo Usage: $0 [options]
    echo
    echo Options,
    echo --skip_setup                      Skip Installing python dependencies. Direclty launch Notebook session
    echo --skip_models_download            Skip Pre-compiled models download
    exit 0
    ;;
esac
shift # past argument
done
set -- "${POSITIONAL[@]}" # restore positional parameters


echo "# ##################################################################"
echo "This script download python modules, edgeai-benchmark, and some precompiled models artifacts.
It also sets other requirements, and, at the end, it launches jupyter notebook server in the EVM
Note: take a note of the EVM's ip address before running this scrip (ifconfig)
and use it in a computer's web browser to access and run the notebooks. ex: http://192.168.1.199:8888"

echo "# ##################################################################"

if [ $skip_setup -eq 0 ]
then
echo "Installing python modules
This step is required only the first time"
pip3 install numpy==1.19.5
pip3 install pycocotools
pip3 install colorama
pip3 install pytest
pip3 install notebook
pip3 install ipywidgets
pip3 install papermill --ignore-installed
pip3 install munkres
pip3 install json_tricks
pip3 install git+https://github.com/jin-s13/xtcocoapi.git
pip3 install h5py
pip3 install scipy
jupyter nbextension enable --py widgetsnbextension

echo "# ##################################################################"
echo "Clone and install jacinto-ai python module
This could take some time..
This step is required only the first time"
cd ../
git clone --single-branch -b master https://github.com/TexasInstruments/edgeai-benchmark.git
cd edgeai-benchmark
pip3 install -e ./
cd ../jupyter_notebooks
fi

if [ $skip_models_download -eq 0 ]
then
echo "# ##################################################################"
echo "Download pre-compiled models
For additional models visit: https://software-dl.ti.com/jacinto7/esd/modelzoo/latest/docs/html/index.html
This step is required only the first time"
mkdir prebuilt-models
mkdir prebuilt-models/8bits
cd prebuilt-models/8bits

wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/cl-0000_tflitert_mlperf_mobilenet_v1_1.0_224_tflite.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/3dod-7100_onnxrt_mmdetection3d_lidar_point_pillars_496x432_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/kd-7000_onnxrt_edgeai-mmpose_mobilenetv2_fpn_spp_udp_512_20210610_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/cl-3410_tvmdlr_gluoncv-mxnet_mobilenetv2_1.0-symbol_json.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/cl-6061_onnxrt_edgeai-tv_mobilenet_v1_20190906_512x512_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/cl-6060_onnxrt_edgeai-tv_mobilenet_v1_20190906_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/od-5020_tvmdlr_gluoncv-mxnet_yolo3_mobilenet1.0_coco-symbol_json.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/od-8000_onnxrt_mlperf_ssd_resnet34-ssd1200_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/od-2000_tflitert_mlperf_ssd_mobilenet_v1_coco_20180128_tflite.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/ss-5720_tvmdlr_edgeai-tv_fpn_aspp_regnetx800mf_edgeailite_512x512_20210405_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/ss-8690_onnxrt_edgeai-tv_fpn_aspp_regnetx400mf_edgeailite_384x384_20210314_outby4_onnx.tar.gz
wget http://software-dl.ti.com/jacinto7/esd/modelzoo/08_01_00_05/modelartifacts/8bits/ss-2580_tflitert_mlperf_deeplabv3_mnv2_ade20k32_float_tflite.tar.gz

find . -name "*.tar.gz" -exec tar --one-top-level -zxvf "{}" \;
cd ../../
fi

echo "# ##################################################################"
echo "Setup the environment
This step is required everytime notebook server is launched"

if [[ -z "$TIDL_TOOLS_PATH" ]]
then
echo "Setting TIDL_TOOLS_PATH. Note: TIDL_TOOLS_PATH needs to exist for jacinto-ai module, but, this is a dummy path.."
export TIDL_TOOLS_PATH="/opt/jai_tidl_notebooks"
echo "TIDL_TOOLS_PATH=${TIDL_TOOLS_PATH}"
fi

export TIDL_RT_DDR_STATS="1"
export TIDL_RT_PERFSTATS="1"
echo "TIDL_RT_PERFSTATS=${TIDL_RT_PERFSTATS}"

echo "# ##################################################################"
echo "Launch notebook server"
jupyter notebook --allow-root --no-browser --ip=0.0.0.0

