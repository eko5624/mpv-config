--[[

快捷指令增强

input.conf 示例：

 #                    script-binding input_plus/mark_aid_A          # 标记当前音轨为A
 #                    script-binding input_plus/mark_aid_B          # 标记当前音轨为B
 #                    script-binding input_plus/mark_aid_merge      # 合并AB音轨
 #                    script-binding input_plus/mark_aid_reset      # 取消AB并轨和标记
 m                    script-binding input_plus/mark_aid_fin        # （单键实现上述四项命令）

 Alt+p                script-binding input_plus/playlist_order_0    # 播放列表的洗牌与撤销
 #                    script-binding input_plus/playlist_order_0r   # ...（重定向至首个文件）
 #                    script-binding input_plus/playlist_order_1    # 播放列表连续洗牌（可用上两项命令恢复）
 #                    script-binding input_plus/playlist_order_1r   # ...

 CLOSE_WIN            script-binding input_plus/quit_real           # 对执行退出命令前的确认（防止误触）
 #                    script-binding input_plus/quit_wait           # 延后退出命令的执行（执行前再次触发可取消）

 #                    script-binding input_plus/seek_auto_back      # [可持续触发] 后退至上句字幕的时间点或上一关键帧
 #                    script-binding input_plus/seek_auto_next      # [可持续触发] 前进至下...
 #                    script-binding input_plus/seek_skip_back      # 向后大跳（精确帧）
 #                    script-binding input_plus/seek_skip_next      # 向前...

 SPACE                script-binding input_plus/speed_auto          # [按住/松开] 两倍速/一倍速
 #                    script-binding input_plus/speed_auto_bullet   # [按住/松开] 子弹时间/一倍速
 #                    script-binding input_plus/speed_recover       # 仿Pot的速度重置与恢复

 #                    script-binding input_plus/stats_1_2           # 单键浏览统计数据第1至2页
 #                    script-binding input_plus/stats_0_4           # 单键浏览统计数据第0至4页

 #                    script-binding input_plus/trackA_back         # 上一个音频轨道（自动跳过无轨道）
 #                    script-binding input_plus/trackA_next         # 下...
 #                    script-binding input_plus/trackS_back         # 上一个字幕轨道...
 #                    script-binding input_plus/trackS_next         # 下...
 #                    script-binding input_plus/trackV_back         # 上一个视频轨道...
 #                    script-binding input_plus/trackV_next         # 下...

 #                    script-binding input_plus/x264_cmpt           # 开/关 旧版x264即时兼容模式

--]]


local marked_aid_A = nil
local marked_aid_B = nil
local merged_aid = false
function mark_aid_A()
	marked_aid_A = mp.get_property_number("aid", 0)
	if marked_aid_A == 0
	then
		mp.osd_message("当前音轨无效", 1)
		marked_aid_A = nil
	else
		mp.osd_message("预标记当前音轨序列 " .. marked_aid_A .. " 为并行轨A", 1)
	end
end
function mark_aid_B()
	marked_aid_B = mp.get_property_number("aid", 0)
	if marked_aid_B == 0
	then
		mp.osd_message("当前音轨无效", 1)
		marked_aid_B = nil
	else
		mp.osd_message("预标记当前音轨序列 " .. marked_aid_B .. " 为并行轨B", 1)
	end
end
function mark_aid_merge()
	if marked_aid_A == marked_aid_B or marked_aid_A == nil or marked_aid_B == nil
	then
		mp.osd_message("无效的AB音轨", 1)
		marked_aid_A, marked_aid_B = nil, nil
	else
		mp.command("set lavfi-complex \"[aid" .. marked_aid_A .. "] [aid" .. marked_aid_B .. "] amix [ao]\"")
		mp.osd_message("已合并AB音轨", 1)
		merged_aid = true
	end
end
function mark_aid_reset()
	mp.command("set lavfi-complex \"\"")
	merged_aid = false
	marked_aid_A, marked_aid_B = nil, nil
end
function mark_aid_fin()
	if merged_aid then
		mark_aid_reset()
		mp.osd_message("已取消并轨和标记", 1)
		mp.commandv("set", "aid", "auto")
		return
	end
	if marked_aid_A == nil then
		mark_aid_A()
		return
	end
	if marked_aid_B == nil then
		mark_aid_B()
		return
	end
	mark_aid_merge()
end

local shuffled = false
local shuffling = false
function show_playlist()
	mp.add_timeout(0.1, function()
		local shuffle_msg = mp.command_native({"expand-text", "${playlist}"})
		shuffling = false
		mp.osd_message(shuffle_msg, 2)
	end)
end
function playlist_order(mode, re)
	if shuffling then
		mp.msg.info("已阻止高频洗牌")
		return
	end
	if mp.get_property_number("playlist-count") <= 2 then
		mp.osd_message("播放列表中的条目数量不足", 1)
		return
	end
	shuffling = true
	if mode == 0 then
		if not shuffled then
			mp.command("playlist-shuffle")
			shuffled = true
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist()
		else
			mp.command("playlist-unshuffle")
			shuffled = false
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist()
		end
	elseif mode == 1 then
		if shuffled then
			mp.command("playlist-unshuffle")
			mp.command("playlist-shuffle")
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist()
		else
			mp.command("playlist-shuffle")
			shuffled = true
			if re then
				mp.commandv("playlist-play-index", 0)
			end
			show_playlist()
		end
	end
end

local pre_quit = false
function quit_real()
	if pre_quit then
		mp.command("quit")
	else
		mp.osd_message("再次执行以确认退出", 1)
		pre_quit = true
		mp.add_timeout(1, function()
			pre_quit = false
			mp.msg.verbose("quit_real 检测到误触退出键")
		end)
	end
end
function quit_wait()
	if pre_quit then
		pre_quit = false
		return
	else
		pre_quit = true
		mp.osd_message("即将退出，再次执行以取消", 3)
		mp.add_timeout(3, function()
			if pre_quit then
				mp.command("quit")
			else
				mp.osd_message("已取消退出", 0.5)
				return
			end
		end)
	end
end

function seek_auto(num)
	local current_sid = mp.get_property_number("sid", 0)
	if current_sid == 0 then
		mp.command("seek " .. 0.1 * num .. " keyframes")
	else
		mp.command("sub-seek " .. num .. " primary")
	end
end
function seek_skip(num)
	local duration_div_chapters = mp.get_property_number("duration", 1) / mp.get_property_number("chapter-list/count", 1)
	if duration_div_chapters >= 240 then
		mp.command("seek " .. 10 * num .. " relative-percent+exact")
	elseif duration_div_chapters == 1 then
		mp.command("seek " .. 60 * num .. " exact")
	else
		mp.commandv("add", "chapter", num)
		mp.command("show-progress")
	end
end

local bak_speed = nil
function speed_auto(tab)
	if tab.event == "down" then
		mp.set_property_number("speed", 2)
		mp.msg.verbose("speed_auto 加速播放中")
	elseif tab.event == "up" then
		mp.set_property_number("speed", 1)
		mp.msg.verbose("speed_auto 已恢复常速")
	end
end
function speed_auto_bullet(tab)
	if tab.event == "down" then
		mp.set_property_number("speed", 0.5)
		mp.msg.verbose("speed_auto_bullet 子弹时间中")
	elseif tab.event == "up" then
		mp.set_property_number("speed", 1)
		mp.msg.verbose("speed_auto_bullet 已恢复常速")
	end
end
function speed_recover()
	if mp.get_property_number("speed") ~= 1 then
		bak_speed = mp.get_property_number("speed")
		mp.command("set speed 1")
	else
		if bak_speed == nil then
			bak_speed = 1
		end
		mp.command("set speed " .. bak_speed)
	end
end

local show_page = 0
function stats_cycle(num_init, num_end)
	if show_page < num_init then
		show_page = num_init - 1
	end
	if show_page >= num_end then
		show_page = num_init - 1
	end
	show_page = show_page + 1
	mp.command("script-binding stats/display-page-" .. show_page)
end

function track_seek(id, num)
	mp.command("add " .. id .. " " .. num)
	if mp.get_property_number(id, 0) == 0 then
		mp.command("add " .. id .. " " .. num)
		if mp.get_property_number(id, 0) == 0 then
			mp.osd_message("无可用轨道", 1)
		end
	end
end

local temp_avc = false
local x264_cmpt_warn = tostring("x264_cmpt 可能破坏常规h264文件的播放")
function x264_cmpt()
	local current_vid = mp.get_property_number("vid", 0)
	if current_vid == 0 then
		mp.osd_message("当前视频轨道无效", 1)
		return
	end
	if temp_avc then
		mp.set_property_bool("vd-lavc-assume-old-x264", false)
		temp_avc = false
		mp.osd_message("已禁用旧版x264即时兼容模式", 1)
		mp.set_property_number("vid", 0)
		mp.set_property_number("vid", current_vid)
		return
	end
	mp.set_property_bool("vd-lavc-assume-old-x264", true)
	temp_avc = true
	mp.osd_message("已启用旧版x264即时兼容模式", 1)
	mp.msg.warn(x264_cmpt_warn)
	mp.set_property_number("vid", 0)
	mp.set_property_number("vid", current_vid)
end


--
-- 事件注册
--

mp.register_event("end-file", function() if marked_aid_A ~= nil or marked_aid_B ~= nil then mark_aid_reset() end end)

--mp.register_event("end-file", function() if temp_avc then mp.set_property_bool("vd-lavc-assume-old-x264", false) temp_avc = false end end)
mp.register_event("start-file", function() if temp_avc then mp.msg.warn(x264_cmpt_warn) end end)


--
-- 键位绑定
--

mp.add_key_binding(nil, "mark_aid_A", mark_aid_A)
mp.add_key_binding(nil, "mark_aid_B", mark_aid_B)
mp.add_key_binding(nil, "mark_aid_merge", mark_aid_merge)
mp.add_key_binding(nil, "mark_aid_reset", function() mark_aid_reset() mp.osd_message("已取消并轨和标记", 1) end)
mp.add_key_binding(nil, "mark_aid_fin", mark_aid_fin)

mp.add_key_binding(nil, "playlist_order_0", function() playlist_order(0) end)
mp.add_key_binding(nil, "playlist_order_0r", function() playlist_order(0, true) end)
mp.add_key_binding(nil, "playlist_order_1", function() playlist_order(1) end)
mp.add_key_binding(nil, "playlist_order_1r", function() playlist_order(1, true) end)

mp.add_key_binding(nil, "quit_real", quit_real)
mp.add_key_binding(nil, "quit_wait", quit_wait)

mp.add_key_binding(nil, "seek_auto_back", function() seek_auto(-1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_auto_next", function() seek_auto(1) end, {repeatable = true})
mp.add_key_binding(nil, "seek_skip_back", function() seek_skip(-1) end)
mp.add_key_binding(nil, "seek_skip_next", function() seek_skip(1) end)

mp.add_key_binding(nil, "speed_auto", speed_auto, {complex = true})
mp.add_key_binding(nil, "speed_auto_bullet", speed_auto_bullet, {complex = true})
mp.add_key_binding(nil, "speed_recover", speed_recover)

mp.add_key_binding(nil, "stats_1_2", function() stats_cycle(1, 2) end)
mp.add_key_binding(nil, "stats_0_4", function() stats_cycle(0, 4) end)

mp.add_key_binding(nil, "trackA_back", function() track_seek("aid", -1) end)
mp.add_key_binding(nil, "trackA_next", function() track_seek("aid", 1) end)
mp.add_key_binding(nil, "trackS_back", function() track_seek("sid", -1) end)
mp.add_key_binding(nil, "trackS_next", function() track_seek("sid", 1) end)
mp.add_key_binding(nil, "trackV_back", function() track_seek("vid", -1) end)
mp.add_key_binding(nil, "trackV_next", function() track_seek("vid", 1) end)

mp.add_key_binding(nil, "x264_cmpt", x264_cmpt)
