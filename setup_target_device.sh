#!/bin/bash

# Copyright (c) 2024, Texas Instruments
# All Rights Reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

######################################################################
SCRIPTDIR=`pwd`
TARGET_FS_PATH=/

# List of supported REL versions for backward compatibility
SUPPORTED_REL=("10_00_07_00")

REL=${REL:-"10_00_07_00"}
UPDATE_OSRT_COMPONENTS=${UPDATE_OSRT_COMPONENTS:-1}
UPDATE_FIRMWARE_AND_LIB=${UPDATE_FIRMWARE_AND_LIB:-0}

echo "REL: ${REL}"
echo "UPDATE_OSRT_COMPONENTS: ${UPDATE_OSRT_COMPONENTS}"
echo "UPDATE_FIRMWARE_AND_LIB: ${UPDATE_FIRMWARE_AND_LIB}"

if [ `arch` != "aarch64" ]; then
    echo "The script must be invoked on aarch64 system"
    exit -1
fi

verify_env() {

    rel_found=0
    for i in "${SUPPORTED_REL[@]}"
    do
        if [[ $i == $REL ]];then
            rel_found=1
        fi
    done

    if [[ "$rel_found" -ne "1" ]]; then
        echo
        echo "Unsupported REL: ${REL}"
        echo "Supported Versions are:"
        for i in "${SUPPORTED_REL[@]}"
        do
            echo "${i}"
        done
        return 1
    fi

    if [ "$SOC" != "am62" ] && [ "$SOC" != "am62a" ] &&
    [ "$SOC" != "am68a" ] && [ "$SOC" != "am68pa" ] &&
    [ "$SOC" != "am69a" ] && [ "$SOC" != "am67a" ]; then
        echo
        echo "Incorrect SOC defined: $SOC"
        echo "Run either of below commands"
        echo "export SOC=am62"
        echo "export SOC=am62a"
        echo "export SOC=am68a"
        echo "export SOC=am68pa"
        echo "export SOC=am69a"
        echo "export SOC=am67a"
        return 1
    fi

    if [ "$TISDK_IMAGE" != "adas" ] && [ "$TISDK_IMAGE" != "edgeai" ]; then
        echo
        echo "Incorrect TISDK_IMAGE defined: $TISDK_IMAGE"
        echo "Run either of below commands"
        echo "export TISDK_IMAGE=edgeai"
        echo "export TISDK_IMAGE=adas"
        return 1
    fi

    return 0
}

update_osrt_components() {
    echo
    echo "Updating OSRT components"

    cd $TARGET_FS_PATH/$HOME

    if [ ! -d arago_j7_pywhl ];then
        mkdir arago_j7_pywhl
    fi
    if [ ! -d required_libs ];then
        mkdir required_libs
    fi

    # Updating DLR
    cd $TARGET_FS_PATH/$HOME/arago_j7_pywhl

    echo "==================== Updating dlr runtime wheel ===================="
    wget --proxy off https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/OSRT_TOOLS/ARM_LINUX/ARAGO/dlr-1.13.0-py3-none-any.whl
    pip3 install --upgrade --force-reinstall dlr-1.13.0-py3-none-any.whl --disable-pip-version-check

    echo "==================== Updating arm-tidl headers ===================="
    cd $TARGET_FS_PATH/$HOME/required_libs
    git clone -b master git://git.ti.com/processor-sdk-vision/arm-tidl.git

    if [ "$?" -eq "0" ]; then
        # Backup old file
        if [ ! -f "$TARGET_FS_PATH/usr/include/itidl_rt.h.bkp" ]; then
            mv $TARGET_FS_PATH/usr/include/itidl_rt.h $TARGET_FS_PATH/usr/include/itidl_rt.h.bkp
        fi
        # Backup old file
        if [ ! -f "$TARGET_FS_PATH/usr/include/itvm_rt.bkp" ]; then
            mv $TARGET_FS_PATH/usr/include/itvm_rt.h $TARGET_FS_PATH/usr/include/itvm_rt.bkp
        fi
        cp arm-tidl/rt/inc/itidl_rt.h  $TARGET_FS_PATH/usr/include/
        cp arm-tidl/rt/inc/itvm_rt.h $TARGET_FS_PATH/usr/include/
    fi

    cd $TARGET_FS_PATH/$HOME/

    # Updating ONNX
    cd $TARGET_FS_PATH/$HOME/arago_j7_pywhl

    echo "==================== Updating onnxruntime wheel ===================="
    wget --proxy off https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/OSRT_TOOLS/ARM_LINUX/ARAGO/onnxruntime_tidl-1.14.0+10000005-cp310-cp310-linux_aarch64.whl
    pip3 install onnxruntime_tidl-1.14.0+10000005-cp310-cp310-linux_aarch64.whl --disable-pip-version-check

    cd $TARGET_FS_PATH/$HOME/required_libs

    echo "==================== Updating onnxruntime components ===================="
    wget --proxy off https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/OSRT_TOOLS/ARM_LINUX/ARAGO/onnx_1.14.0_aragoj7.tar.gz
    if [ "$?" -eq "0" ]; then
        tar xf onnx_1.14.0_aragoj7.tar.gz && rm onnx_1.14.0_aragoj7.tar.gz

        # Backup old directory
        if [ ! -d "$TARGET_FS_PATH/usr/include/onnxruntime.bkp" ]; then
            mv $TARGET_FS_PATH/usr/include/onnxruntime $TARGET_FS_PATH/usr/include/onnxruntime.bkp
        fi
        rm -rf $TARGET_FS_PATH/usr/include/onnxruntime
        mv onnx_1.14.0_aragoj7/onnxruntime $TARGET_FS_PATH/usr/include/
        
        # Backup old file
        if [ ! -f "$TARGET_FS_PATH/usr/lib/libonnxruntime.so.1.14.0+10000005.bkp" ]; then
            mv $TARGET_FS_PATH/usr/lib/libonnxruntime.so.1.14.0+10000005 $TARGET_FS_PATH/usr/lib/libonnxruntime.so.1.14.0+10000005.bkp
        fi
        cp -r  onnx_1.14.0_aragoj7/libonnxruntime.so.1.14.0+10000005   $TARGET_FS_PATH/usr/lib/
        cd   $TARGET_FS_PATH/usr/lib/
        ln -sf libonnxruntime.so.1.14.0+10000005 libonnxruntime.so
    fi

    cd $TARGET_FS_PATH/$HOME/

    # Updating TFLITE
    cd $TARGET_FS_PATH/$HOME/arago_j7_pywhl

    echo "==================== Updating tflite wheel ===================="
    wget --proxy off https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/OSRT_TOOLS/ARM_LINUX/ARAGO/tflite_runtime-2.12.0-cp310-cp310-linux_aarch64.whl
    pip3 install --upgrade --force-reinstall tflite_runtime-2.12.0-cp310-cp310-linux_aarch64.whl --disable-pip-version-check

    cd $TARGET_FS_PATH/$HOME/required_libs

    echo "==================== Updating tflite components ===================="
    wget --proxy off https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/OSRT_TOOLS/ARM_LINUX/ARAGO/tflite_2.12_aragoj7.tar.gz
    if [ "$?" -eq "0" ]; then
        tar xf tflite_2.12_aragoj7.tar.gz && rm tflite_2.12_aragoj7.tar.gz
        
        # Backup old directory
        if [ ! -d "$TARGET_FS_PATH/usr/include/tensorflow.bkp" ]; then
            mv $TARGET_FS_PATH/usr/include/tensorflow $TARGET_FS_PATH/usr/include/tensorflow.bkp
        fi
        rm -rf $TARGET_FS_PATH/usr/include/tensorflow
        mv tflite_2.12_aragoj7/tensorflow  $TARGET_FS_PATH/usr/include

        # Backup old directory
        if [ ! -d "$TARGET_FS_PATH/usr/lib/tflite_2.12.bkp" ]; then
            mv $TARGET_FS_PATH/usr/lib/tflite_2.12 $TARGET_FS_PATH/usr/lib/tflite_2.12.bkp
        fi
        rm -rf $TARGET_FS_PATH/usr/lib/tflite_2.12
        mv tflite_2.12_aragoj7/tflite_2.12  $TARGET_FS_PATH/usr/lib/

        # Backup old file
        if [ ! -f "$TARGET_FS_PATH/usr/lib/libtensorflow-lite.a.bkp" ]; then
            mv $TARGET_FS_PATH/usr/lib/libtensorflow-lite.a $TARGET_FS_PATH/usr/lib/libtensorflow-lite.a.bkp
        fi
        cp tflite_2.12_aragoj7/libtensorflow-lite.a $TARGET_FS_PATH/usr/lib/
    fi

    cd $TARGET_FS_PATH/$HOME/

    # Updating NUMPY
    pip3 install --upgrade --force-reinstall --no-cache-dir numpy==1.23.0 --disable-pip-version-check

    # Cleanup
    rm -rf $TARGET_FS_PATH/$HOME/arago_j7_pywhl
    rm -rf $TARGET_FS_PATH/$HOME/required_libs
}

update_firmware_and_lib() {
    echo "Updating Firmwares"
    cd $TARGET_FS_PATH/$HOME

    if [ ! -d updated_firmware_and_lib ];then
        mkdir updated_firmware_and_lib
    fi

    cd $TARGET_FS_PATH/$HOME/updated_firmware_and_lib

    FIRMWARE_TARBALL=https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/FIRMWARES/$SOC/$TISDK_IMAGE/firmware.tar.gz
    TIDL_LIB_TARBALL=https://software-dl.ti.com/jacinto7/esd/tidl-tools/$REL/FIRMWARES/$SOC/$TISDK_IMAGE/tidl_lib.tar.gz

    echo "==================== Updating C7X firmware ===================="
    if [ "${TISDK_IMAGE}" == "edgeai" ]; then
        FIRMWARE_PATH=$TARGET_FS_PATH/lib/firmware/vision_apps_eaik
    else
        FIRMWARE_PATH=$TARGET_FS_PATH/lib/firmware/vision_apps_evm
    fi
    echo "FIRMWARE_PATH: ${FIRMWARE_PATH}"
    wget --proxy off $FIRMWARE_TARBALL
    if [ "$?" -ne "0" ]; then
        echo "Downloading firmware failed. Please check if $FIRMWARE_TARBALL is valid"
    fi
    tar -xf firmware.tar.gz && rm firmware.tar.gz
    cd firmware
    for file in *; do
        echo "Replacing ${file}"
        # Backup files
        if [ -f $FIRMWARE_PATH/$file ]; then
            if [ ! -f "$FIRMWARE_PATH/$file.bkp" ]; then
                mv $FIRMWARE_PATH/$file $FIRMWARE_PATH/$file.bkp
            fi
        else
            echo "WARNING: $file not used in $FIRMWARE_PATH. Still copying"
        fi
        cp $file $FIRMWARE_PATH/
    done

    cd $TARGET_FS_PATH/$HOME/updated_firmware_and_lib

    echo "==================== Updating TIDL lib ===================="
    wget --proxy off $TIDL_LIB_TARBALL
    if [ "$?" -ne "0" ]; then
        echo "Downloading tidl_lib failed. Please check if $TIDL_LIB_TARBALL is valid"
    fi
    tar -xf tidl_lib.tar.gz && rm tidl_lib.tar.gz
    cd tidl_lib
    for file in *; do
        echo "Replacing ${file}"
        # Backup files
        if [ -f $TARGET_FS_PATH/usr/lib/$file ]; then
            if [ ! -f "$TARGET_FS_PATH/usr/lib/$file.bkp" ]; then
                mv $TARGET_FS_PATH/usr/lib/$file $TARGET_FS_PATH/usr/lib/$file.bkp
            fi
        else
            echo "WARNING: $file not used. Still copying"
        fi
        cp $file $TARGET_FS_PATH/usr/lib
    done

    # Cleanup
    rm -rf $TARGET_FS_PATH/$HOME/updated_firmware_and_lib
}

verify_env
if [ "$?" -eq "0" ]; then
    if [ "${UPDATE_OSRT_COMPONENTS}" -eq "1" ]; then
        update_osrt_components
    fi
    if [ "${UPDATE_FIRMWARE_AND_LIB}" -eq "1" ]; then
        update_firmware_and_lib
    fi
fi

cd $SCRIPTDIR