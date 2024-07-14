#!/bin/bash


source installer.cfg


function display_message {

	clear
	echo $1
	sleep 5
}

function update_sys {

	display_message "Updating Ubuntu using apt-get update"
	apt-get update

	display_message "Installing required packages"

	apt-get install -y autoconf automake build-essential mercurial git libarchive-dev fontconfig checkinstall
	apt-get install -y libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libgnutls-dev
	apt-get install -y libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo libtool libva-dev
	apt-get install -y libbs2b-dev libcaca-dev libopenjpeg-dev librtmp-dev libvpx-dev libvdpau-dev
	apt-get install -y libwavpack-dev libxvidcore-dev lzma-dev liblzma-dev zlib1g-dev cmake-curses-gui
	apt-get install -y libx11-dev libxfixes-dev libmp3lame-dev libx264-dev libbz2-dev libbluray-dev

	sleep 5
}


function install_libnuma {

	NUMA_LIB="numactl-2.0.11.tar.gz"
	NUMA_PATH=$(basename ${NUMA_LIB} .tar.gz)

	cd ${SOURCE_PREFIX}

	if [ ! -d "${NUMA_PATH}" ];then

        	wget -O ${NUMA_LIB} "ftp://oss.sgi.com/www/projects/libnuma/download/${NUMA_LIB}"
	fi

	tar xfzv ${NUMA_LIB}
	cd ${NUMA_PATH}
	./configure
	make
	make install

	sleep 5
}


function install_libopus {

	      OPUS_LIB=opus-1.5.2.tar.gz
        OPUS_PATH=$(basename ${OPUS_LIB} .tar.gz)

        cd ${SOURCE_PREFIX}

        if [ ! -d "${OPUS_PATH}" ];then

                wget http://downloads.xiph.org/releases/opus/${OPUS_LIB}

        fi

        tar xzvf ${OPUS_LIB}
        cd ${OPUS_PATH}
        ./configure --prefix="${INST_PREFIX}" --disable-shared
        make
        make install
	make check
        make clean

	sleep 5
}


function install_cmake {

        cd ${SOURCE_PREFIX}

	#Need further testing
	if [ ! -d "CMake" ];then

		git clone https://github.com/Kitware/CMake

	fi

	cd CMake
        ./bootstrap --prefix="/usr/local"
        make
        make install

	sleep 5
}


function install_aac {

	AAC_LIB="fdk-aac.tar.gz"

	cd ${SOURCE_PREFIX}

	if [ ! -d "mstorsjo-fdk-aac*" ];then

        	wget -O ${AAC_LIB} https://github.com/mstorsjo/fdk-aac/tarball/master
	fi

	tar xzvf ${AAC_LIB}
	cd mstorsjo-fdk-aac*
	autoreconf -fiv
	./configure --prefix="${INST_PREFIX}" --disable-shared
	make
	make install
	make distclean

	sleep 5
}


function install_yasm {

	cd ${SOURCE_PREFIX}

	if [ ! -d "yasm" ];then

        	git clone git://github.com/yasm/yasm.git
	fi

	cd yasm
	./autogen.sh

	./configure
	make
	make install

	sleep 5
}


function install_x265 {

	cd ${SOURCE_PREFIX}

	if [ ! -d "x265" ];then

		hg clone https://bitbucket.org/multicoreware/x265

	fi

	cd x265/build/linux
	cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${INST_PREFIX}" ../../source

	make
	make install

	sleep 5
}


function install_ffmpeg {

	cd ${SOURCE_PREFIX}

	if [ ! -d "ffmpeg" ];then

        	git clone git://source.ffmpeg.org/ffmpeg.git
	fi

	cd ffmpeg

	PKG_CONFIG_PATH="${INST_PREFIX}/pkgconfig" \
	./configure --prefix="${INST_PREFIX}" \
		--pkg-config-flags="--static" \
		--extra-cflags="-I${INST_PREFIX}/include"  \
 		--extra-ldflags="-L${INST_PREFIX}/lib" \
 		--enable-gpl \
 		--enable-libass \
 		--enable-libbluray \
 		--enable-fontconfig \
 		--enable-bzlib \
 		--enable-gnutls \
 		--enable-libbs2b \
 		--enable-libcaca \
 		--enable-zlib \
 		--enable-libopenjpeg \
 		--enable-librtmp \
 		--enable-libvo-amrwbenc \
 		--enable-libwavpack \
 		--enable-lzma \
 		--enable-libfdk-aac \
 		--enable-libfreetype \
 		--enable-libmp3lame \
 		--enable-libopus \
 		--enable-libtheora \
 		--enable-libvpx  \
		--enable-libx264 \
 		--enable-libx265 \
 		--enable-nonfree \
		--enable-version3 \
		--arch=x86_64 \
                --enable-yasm

	make
	make install

	sleep 5
}


function testing {

	cd ${SOURCE_PREFIX}

	"${INST_PREFIX}"/bin/ffmpeg -i ${TEST_VID} -c:v libx265 -c:a aac test.mp4

	if [ $? -eq 0 ];then

        	echo "TEST PASSED!"

	else

        	echo "TEST FAILED!. CONTAINS ERRORS!"
        	exit
	fi

	sleep 5
}


display_message "Update Ubuntu System"
update_sys

#if [ ! -d ${SOURCE_PREFIX} ];then

#	mkdir ${SOURCE_PREFIX}
#fi


if [ ${SOURCE_PREFIX} != "/usr" ];then

	mkdir ${INST_PREFIX}

fi


#Install Latest libnuma
display_message "Installing libnuma-dev"
install_libnuma


#Install libopus
display_message "Installing libopus-dev"
install_libopus


#Install CMAKE
display_message "Installing CMake" | tee logfile
install_cmake

#Install latest libfdk-aac-dev
display_message "Installing fdk-aac" | tee logfile
install_aac


#Install latest YASM
display_message "Installing YASM" | tee logfile
install_yasm

#Use the latest x265 codec
display_message "Installing libx265-dev" | tee logfile
install_x265


#Install ffmpeg
display_message "Installing ffmpeg" | tee logfile
install_ffmpeg


#Conduct testing
display_message "Conduct testing"
testing

echo "DONE!"
sleep 5
