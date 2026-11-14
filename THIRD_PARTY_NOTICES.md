# Third-party notices

## FFmpeg

Squeezy includes the `ffmpeg` and `ffprobe` command-line executables from
[FFmpeg](https://ffmpeg.org/), version **9.0.2**.

Copyright belongs to the respective FFmpeg authors and contributors.
FFmpeg is an independent project; Squeezy is not affiliated with or endorsed
by the FFmpeg project.

The FFmpeg executables used by Squeezy are built for macOS ARM64, with a
restricted set of features. The project's build configuration intentionally
excludes GPL and nonfree components. For that configuration, FFmpeg is
licensed under the **GNU Lesser General Public License, version 2.1 or later
(LGPL-2.1-or-later)**. The full LGPL 2.1 text is included at
[`licenses/FFmpeg-LGPL-2.1.txt`](licenses/FFmpeg-LGPL-2.1.txt).

### Source code and build instructions

- Upstream project: https://ffmpeg.org/
- Source release: https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz
- Source signature: https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz.asc
- Build and configuration: [`scripts/build-ffmpeg.sh`](scripts/build-ffmpeg.sh)

Squeezy runs the bundled FFmpeg programs as separate processes; the Swift
application does not link directly against FFmpeg libraries. The executable
files themselves incorporate statically linked FFmpeg components.

### Redistribution

Distributors of Squeezy builds that bundle FFmpeg must also satisfy the
applicable LGPL obligations, including providing the corresponding FFmpeg
source code and adequate build information for the particular binaries they
distribute. An upstream link alone should not be assumed sufficient for every
distribution method.

For official binary releases, provide the exact corresponding FFmpeg source
archive, license material, build configuration, and any modifications alongside
the release, or by another method that meets the license requirements.

The MIT license in this repository applies to Squeezy's own code and does not
replace FFmpeg's license.
