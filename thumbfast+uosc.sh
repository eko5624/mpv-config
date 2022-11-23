#!/bin/bash
set -x

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

[ ! -d "$DIR/thumbfast+uosc/scripts" ] || mkdir -p $DIR/thumbfast+uosc/scripts
[ ! -d "$DIR/thumbfast+uosc/script-opts" ] || mkdir -p $DIR/thumbfast+uosc/script-opts

cd $DIR/thumbfast+uosc

# get thumbfast
git clone https://github.com/po5/thumbfast.git --branch master
cp -f thumbfast/thumbfast.lua scripts  
cp -f thumbfast/thumbfast.conf script-opts
rm -rf thumbfast

#Change thumb size from 200px to 360px
sed -i 's/max_height=200/max_height=360/' script-opts/thumbfast.conf
sed -i 's/max_width=200/max_width=360/' script-opts/thumbfast.conf

# get uosc
git clone https://github.com/tomasklaen/uosc.git --branch main
rm -rf fonts
cp -r uosc/fonts ./
cp -rf uosc/scripts/* scripts
cp -f uosc/script-opts/uosc.conf script-opts
rm -rf uosc

# Don't dim screen when triggering menu.
sed -i 's/curtain_opacity=0.5/curtain_opacity=0/' script-opts/uosc.conf

# Add 'prev/next chapter' button and 'open-file' button.
sed -i 's/gap,subtitles,<has_many_audio>audio,<has_many_video>video/script-stats,open-file,gap,<has_chapter>command:skip_previous:add chapter -1?上一章节,play_pause,<has_chapter>command:skip_next:add chapter 1?下一章节,gap,subtitles,audio,<has_chapter>chapters/' script-opts/uosc.conf

sed -i "/subtitles =/i \t\t['play_pause'] = 'cycle:play_arrow:pause:no=pause\/yes=play_arrow?播放/暂停'," scripts/uosc_shared/elements/Controls.lua
sed -i "/subtitles =/a \t\t['script-stats'] = 'command:analytics:script-binding stats/display-stats-toggle?统计数据'," scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Menu/?菜单/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Subtitles/?字幕轨/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Audio/?音频轨/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Audio device/?音频设备/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Video/?视频轨/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Playlist/?播放列表/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Chapters/?章节/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Editions/?版本/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Stream quality/?流品质/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Open file/?加载文件/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Playlist\/Files/?播放列表\/文件浏览器/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Previous/?上一个/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Next/?下一个/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?First/?首位/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Last/?末位/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Loop playlist/?列表循环/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Loop file/?单曲循环/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Shuffle/?乱序播放/' scripts/uosc_shared/elements/Controls.lua
sed -i 's/?Fullscreen/?切换全屏/' scripts/uosc_shared/elements/Controls.lua




