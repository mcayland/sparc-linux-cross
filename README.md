# sparc-linux-cross

This repository contains a Dockerfile for generating a sparc-linux-gnu cross-compiler
suitable for building sparc and sparc32plus binaries, primarily for testing QEMU's
`qemu-sparc` and `qemu-sparc32plus` user emulation.

The main issue as noted in the Dockerfile is that glibc has dropped support for
sparcv8, which leaves the 32-bit default as sparcv8plus as used by the sparcv9 or
the LEON cpu. The result of this is that a cross-compiler using an upstream glibc can 
generate binaries containing the `cas` instruction which is not available in sparcv8,
causing an illegal instruction error to be generated when executed in QEMU's native
qemu-sparc emulation.

The container image generated by this Dockerfile contains a sparc-linux-gnu
cross-compiler that can be used to generate both sparcv8 and sparcv8plus binaries on
an x86 host.


## Example usage

* Generating an EM_SPARC binary for use with qemu-sparc

  `podman run --rm -it -v $(pwd):/tmp ghcr.io/mcayland/sparc-linux-cross sparc-linux-gnu-gcc -o /tmp/test -static /tmp/catch-syscalls.c`

* Generating an EM_SPARC32PLUS binary for use with qemu-sparc32plus

  `podman run --rm -it -v $(pwd):/tmp ghcr.io/mcayland/sparc-linux-cross sparc-linux-gnu-gcc -mcpu=v9 -o /tmp/test -static /tmp/catch-syscalls.c`
