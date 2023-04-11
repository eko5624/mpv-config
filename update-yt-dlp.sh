#!/bin/bash
set -ex

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd $DIR/macos_config
if [ -f "yt-dlp*" ];then
  rm yt-dlp*
fi

# Get yt-dlp
curl -OL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe
curl -OL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
