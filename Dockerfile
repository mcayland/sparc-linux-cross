FROM debian:12.11 AS base

# Build variables
ENV TARGET=sparc-linux-gnu
ENV PREFIX=/opt/local
ENV SYSROOT=$PREFIX/$TARGET/sysroot

RUN apt-get -y update && \
    apt-get -y install \
        build-essential \
        gawk \
        bison \
        wget \
        python3-dev \
        python3-pexpect \
        python-is-python3 \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        rsync \
        file \
        vim \
        git

WORKDIR /root

# Copy patches directory
COPY patches/ /tmp/patches

# binutils
RUN mkdir binutils && \
    cd binutils && \
    wget https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz && \
    tar Jxf binutils-2.44.tar.xz

RUN cd binutils && \
    mkdir build && \
    cd build && \
    ../binutils-2.44/configure --prefix=$PREFIX --target=$TARGET --with-sysroot=$SYSROOT && \
    make -j4 && \
    make install

# kernel headers
RUN mkdir linux && \
    cd linux && \
    wget https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.11.9.tar.xz && \
    tar Jxf linux-6.11.9.tar.xz

RUN cd linux/linux-6.11.9 && \
    make ARCH=sparc INSTALL_HDR_PATH=$SYSROOT/usr headers_install 

# gcc
RUN mkdir gcc && \
    cd gcc && \
    wget https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-12.5.0/gcc-12.5.0.tar.xz && \
    tar Jxf gcc-12.5.0.tar.xz

# gcc stage 1
RUN cd gcc && \
    mkdir build1 && \
    cd build1 && \
    ../gcc-12.5.0/configure --prefix=$PREFIX --target=$TARGET --with-cpu=supersparc --with-sysroot=$SYSROOT --enable-languages=c --disable-shared --disable-threads --disable-libssp --with-newlib --without-headers && \
    make -j4 all-gcc all-target-libgcc && \
    make install-gcc install-target-libgcc

# glibc
#
# Note that sparcv8 support was removed in glibc-2.23 (and appears to be
# broken in glibc-2.22), so we use glibc-2.21
RUN mkdir glibc && \
    cd glibc && \
    wget https://mirror.cyberbits.eu/gnu/glibc/glibc-2.21.tar.xz && \
    tar Jxf glibc-2.21.tar.xz

# Apply glibc patches for newer binutils
RUN cd glibc/glibc-2.21 && \
    patch -p1 < /tmp/patches/glibc/0001-43c2948756bb6e144c7b871e827bba37d61ad3a3.patch && \
    patch -p1 < /tmp/patches/glibc/0002-b87c1ec3fa398646f042a68f0ce0f7d09c1348c7.patch

RUN cd glibc && \
    mkdir build && \
    cd build && \
    CC=$PREFIX/bin/$TARGET-gcc LD=$PREFIX/bin/$TARGET-ld \
    AR=$PREFIX/bin/$TARGET-ar RANDLIB=$PREFIX/bin/$TARGET-ranlib \
    ../glibc-2.21/configure --prefix=/usr --host=$TARGET --with-headers=$SYSROOT/usr/include --disable-werror libc_cv_forced_unwind=yes && \
    make -j4 && \
    make install-bootstrap-headers=yes install_root=$SYSROOT install install-headers

# gcc stage 2
RUN cd gcc && \
    mkdir build2 && \
    cd build2 && \
    ../gcc-12.5.0/configure --prefix=$PREFIX --target=$TARGET --with-cpu=supersparc --with-sysroot=$SYSROOT --enable-languages=c && \
    make -j4 && \
    make install


# Release
FROM debian:12.11 AS release

RUN apt-get -y update && \
    apt-get -y install \
        libmpc3 \
        file \
        vim

WORKDIR /root

ENV PATH=/opt/local/bin:$PATH

COPY --from=base /opt/local /opt/local

