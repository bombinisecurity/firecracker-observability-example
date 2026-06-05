#!/bin/sh

# 1. Standard Pseudo-Filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys

# 2. Security & Tracing Subsystems (For LSM and Tracepoints)
mkdir -p /sys/kernel/security
mount -t securityfs securityfs /sys/kernel/security

mkdir -p /sys/kernel/debug
mount -t debugfs debugfs /sys/kernel/debug

# TraceFS exposes kernel tracepoints and kprobes.
# Modern kernels usually mount this under /sys/kernel/tracing automatically via sysfs,
# but explicitly mounting it ensures compatibility.
mkdir -p /sys/kernel/tracing
mount -t tracefs tracefs /sys/kernel/tracing

# 3. BPF Virtual Filesystem Subsystem (For BPF Map Pinning)
mkdir -p /sys/fs/bpf
mount -t bpf bpf /sys/fs/bpf

# 4. Mount Modern cgroups v2
mkdir -p /sys/fs/cgroup
mount -t cgroup2 cgroup2 /sys/fs/cgroup


rm -rf /tmp/bombini_events.sock
socat UNIX-LISTEN:/tmp/bombini_events.sock,fork VSOCK-CONNECT:2:5000 &

# Run Bombini
RUST_LOG=info /usr/local/bin/bombini  --event-socket /tmp/bombini_events.sock &

# shell
exec /bin/sh
