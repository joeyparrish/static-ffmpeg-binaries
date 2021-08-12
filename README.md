# static-ffmpeg-binaries

Static binaries of FFmpeg, for multiple OS &amp; CPU combinations, built from
source in a GitHub Actions workflow.

To download binaries, visit the [releases page][releases].


# License

The GitHub Actions workflows and other scripts in this repo are covered by the
Apache license.
Please see the [workflow source][workflow], [API client source][api-client],
[version script source][version-script], and see [the Apache license][apache]
for license details.

The resulting FFmpeg binaries are built using GPL libraries, and are therefore
published under the GPL license.
Please see the [releases page][releases] for binaries, and see [FFmpeg's GPL
license][gpl] for license details.


# How are they built?

FFmpeg and its key dependencies are all built from source and linked statically.
Each run of the GitHub Actions workflow logs the MD5 sums of the binaries, and
it places the MD5 sums into the release notes.  You can see how they were built,
and you can verify that they haven't been tampered with.  The sums in the
workflow logs, release notes, and the binaries should all match.
You can read the details in the [workflow source][workflow].


# Triggering a build

Update the version numbers as needed in the [version file][version-file], then
create a tag on the new commit.  Full builds will be triggered, and binaries
will be attached to a release on the new tag.


[releases]: https://github.com/joeyparrish/static-ffmpeg-binaries/releases
[workflow]: https://github.com/joeyparrish/static-ffmpeg-binaries/blob/main/.github/workflows/release.yaml
[api-client]: https://github.com/joeyparrish/static-ffmpeg-binaries/blob/main/.github/workflows/api-client/main.js
[version-script]: https://github.com/joeyparrish/static-ffmpeg-binaries/blob/main/.github/workflows/get-version.sh
[version-file]: https://github.com/joeyparrish/static-ffmpeg-binaries/blob/main/.github/workflows/versions.txt
[apache]: https://github.com/joeyparrish/static-ffmpeg-binaries/blob/main/LICENSE
[gpl]: https://github.com/FFmpeg/FFmpeg/blob/master/COPYING.GPLv3
