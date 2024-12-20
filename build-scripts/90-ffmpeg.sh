#!/bin/bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x

tag=$(repo-src/get-version.sh ffmpeg)
git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git -b "$tag"
cd ffmpeg

# Set some OS-specific environment variables and flags.
if [[ "$RUNNER_OS" == "Linux" ]]; then
  if ../repo-src/is-alpine.sh; then
    # Truly static builds are only possible in musl-based Alpine Linux.
    # Go for a completely static binary, but this prevents the use of hardware
    # acceleration.
    export CFLAGS="-static"
    export LDFLAGS="-static"
  else
    # We can't build a truly static binary, so we might as well enable hardware
    # acceleration, which uses dynamic libraries and will depend heavily on the
    # OS distribution.
    PLATFORM_CONFIGURE_FLAGS="--enable-vaapi --enable-nvenc"
    # TODO: Is AMF an option for us in this context?

    # This version of ffmpeg will accept NVEnc 11.5.1.3+, but not Ubuntu
    # 22.04's packaged version, 11.5.1.1.  This patch makes it flexible enough
    # to build with the older NVEnc version in Ubuntu Jammy.
    # For code archaeologists, the commits that set the minimum beyond 11.5.1.1
    # were https://github.com/ffmpeg/ffmpeg/commit/5c288a44 (released in n6.0)
    # and https://github.com/ffmpeg/ffmpeg/commit/05f8b2ca (released in n6.1).
    patch -p1 -i ../repo-src/ffmpeg-nvenc-jammy.patch
  fi
elif [[ "$RUNNER_OS" == "macOS" ]]; then
  export CFLAGS="-static"
  # You can't do a _truly_ static build on macOS except the kernel.
  # So don't set LDFLAGS.  See https://stackoverflow.com/a/3801032

  # Enable platform-specific hardware acceleration.
  PLATFORM_CONFIGURE_FLAGS="--enable-videotoolbox"

  # Disable x86 ASM on macOS.  It fails to build with an error about "32-bit
  # absolute addressing is not supported in 64-bit mode".  I'm not sure how
  # else to resolve this, and from my searches, it appears that others are not
  # having this problem with ffmpeg.  This is still a problem with n7.1
  PLATFORM_CONFIGURE_FLAGS="$PLATFORM_CONFIGURE_FLAGS --disable-x86asm --disable-inline-asm"

  # Enable position independent code (PIC).  This resolved a crash on arm64.
  PLATFORM_CONFIGURE_FLAGS="$PLATFORM_CONFIGURE_FLAGS --enable-pic"
elif [[ "$RUNNER_OS" == "Windows" ]]; then
  # /usr/local/incude and /usr/local/lib are not in mingw's include
  # and linker paths by default, so add them.
  export CFLAGS="-static -I/usr/local/include"
  export LDFLAGS="-static -L/usr/local/lib"

  # Convince ffmpeg that we want to build for mingw64 (native
  # Windows), not msys (which involves some posix emulation).  Since
  # we're in an msys environment, ffmpeg reasonably assumes we're
  # building for that environment if we don't specify this.
  PLATFORM_CONFIGURE_FLAGS="--target-os=mingw64"
fi

if ! ./configure \
    --pkg-config-flags="--static" \
    --disable-ffplay \
    --enable-libvpx \
    --enable-libsvtav1 \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-mbedtls \
    --enable-runtime-cpudetect \
    --enable-gpl \
    --enable-version3 \
    --enable-static \
    $PLATFORM_CONFIGURE_FLAGS; then
  cat ffbuild/config.log
  exit 1
fi

make
# No "make install" for ffmpeg.
