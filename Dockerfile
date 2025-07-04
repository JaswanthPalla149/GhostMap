FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    cmake ninja-build g++ git python3 python3-pip \
    qt6-base-dev qt6-declarative-dev qt6-tools-dev qt6-qmltooling-plugins \
    qt6-multimedia-dev \
    pybind11-dev libopencv-dev \
    libgl1-mesa-dev libopengl-dev \
    && apt clean

WORKDIR /app

COPY . .

RUN rm -rf build GPSViewer

RUN cmake -S . -B build -G Ninja
RUN cmake --build build

CMD ["./build/GPSViewer"]
