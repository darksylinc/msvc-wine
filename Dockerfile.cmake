ARG BASE=msvc-wine
FROM $BASE

# Meson needs python3, and requires a native compiler to be available.
# Building ninja requires python. Building dav1d requires nasm.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git build-essential python3 python nasm

WORKDIR /opt

RUN git clone git://github.com/mstorsjo/ninja && \
    cd ninja && \
    git checkout 00ca3e147f55d00a178d0ec1b1268c6793be3e16 && \
    ./configure.py --bootstrap

ENV PATH=/opt/ninja:$PATH

WORKDIR /build
RUN git clone https://gitlab.kitware.com/mstorsjo/cmake && \
    cd cmake && \
    git checkout a5e7a94084245bae5aa141d2720293b378b0fa8d && \
    mkdir build && \
    cd build && \
    ../configure --prefix=/opt/cmake --parallel=$(nproc) -- -DCMAKE_USE_OPENSSL=OFF && \
    make -j$(nproc) && \
    make install

ENV PATH=/opt/cmake/bin:$PATH

RUN git clone git://github.com/mstorsjo/fdk-aac && \
    cd fdk-aac && \
    git checkout 7f328b93ee2aa8bb4e94613b6ed218e7525d8dc0

RUN wineserver -p && \
    wine wineboot && \
    cd fdk-aac && \
    mkdir build-msvc-arm64 && \
    cd build-msvc-arm64 && \
    export PATH=/opt/msvc/bin/arm64:$PATH && \
    CC=cl CXX=cl cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_PROGRAMS=ON -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_CROSSCOMPILING=ON && \
    ninja
