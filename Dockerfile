FROM ubuntu:24.04

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    bc \
    bison \
    flex \
    libelf-dev \
    libssl-dev \
    wget \
    xz-utils \
    dwarves \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Kernel version to build
ARG KERNEL_VERSION=6.8.12

# Download and extract kernel source
RUN wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz && \
    tar xf linux-${KERNEL_VERSION}.tar.xz && \
    rm linux-${KERNEL_VERSION}.tar.xz

WORKDIR /build/linux-${KERNEL_VERSION}

# Copy the minimal kernel config
COPY firecracker-minimal.config .config

# Prepare configuration (set any missing options to defaults)
RUN make olddefconfig

# Build the kernel
# - Use all available cores
# - For firecracker we want the uncompressed "vmlinux" image
RUN make -j$(nproc) ARCH=x86_64 vmlinux  PAHOLE_FLAGS="-j1"

# Copy output to /output directory for easy extraction
RUN mkdir -p /output && \
    cp vmlinux /output/vmlinux-${KERNEL_VERSION}-firecracker-minimal && \
    cp .config /output/config-${KERNEL_VERSION} && \
    ls -lh /output/

# Show the final image info
RUN echo "=== Build Complete ===" && \
    echo "Kernel: vmlinux-${KERNEL_VERSION}-firecracker-minimal" && \
    echo "Size: $(du -h /output/vmlinux-${KERNEL_VERSION}-firecracker-minimal | cut -f1)"

# Default command: copy output to /output-mount if provided
CMD ["sh", "-c", "if [ -d /output-mount ]; then cp /output/* /output-mount/ && echo 'Kernel copied to /output-mount/'; else echo 'Mount a volume to /output-mount to extract the kernel'; fi"]
