<!--
  Licences of work included in Subtle other than its own.
  Author: Alexius Academia
  Date: 2026-11-23
-->
# Notices

## Reel

Subtle's video preview plays with Reel's containers, decoders and playback
code (https://github.com/alexiusacademia/reel), by the same author, under the
GNU Lesser General Public License, version 2.1 or later, the same licence as
Subtle ([LICENSE](LICENSE)).

## FFmpeg

Several of Reel's decoders follow FFmpeg's source code. FFmpeg is licensed
under the GNU Lesser General Public License, version 2.1 or later, the same
licence as Subtle. https://ffmpeg.org

## text

Spell checking uses the `text` library for Tessel (MIT License),
https://tessel-packages.syncster.dev, by the same author.

## whisper.cpp and ffmpeg (not included)

Generating subtitles runs whisper.cpp (`whisper-cli`, MIT License,
https://github.com/ggml-org/whisper.cpp) and the `ffmpeg` program when they
are installed on the computer; neither is part of Subtle. The Whisper models
are downloaded from https://huggingface.co/ggerganov/whisper.cpp (MIT License).
