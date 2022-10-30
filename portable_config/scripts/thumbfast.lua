--[[
SOURCE_ https://github.com/po5/thumbfast/blob/master/thumbfast.lua
COMMIT_ 712aefaaedd5fc9f791146c69f8a774d6621c55e

适配多个OSC类脚本的新缩略图引擎
]]--

local options = {

    socket = "",           -- Socket path (leave empty for auto)
    tnpath = "",           -- 缩略图缓存路径（确保目录真实存在），留空即自动

    max_height = 300,      -- Maximum thumbnail size in pixels (scaled down to fit) Values are scaled when hidpi is enabled
    max_width = 300,

    overlay_id = 42,       -- Overlay id

    spawn_first = false,   -- Spawn thumbnailer on file load for faster initial thumbnails
    network = false,       -- Enable on network playback
    audio = false,         -- Enable on audio playback

    use_lua_io = true,     -- Windows only: don't use subprocess to communicate with socket (warning: blocks, might cause hangs)

    min_duration = 0,      -- 对短视频关闭预览（秒）
    precise = "auto",      -- 预览精度
    hwdec = true,          -- 启用硬解加速
    frequency = 0.1,       -- 解码频率（秒）

}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options)

local winapi = {}
if options.use_lua_io then
    local ffi_loaded, ffi = pcall(require, "ffi")
    if ffi_loaded then
        winapi = {
            ffi = ffi,
            C = ffi.C,
            bit = require("bit"),

            -- WinAPI constants
            GENERIC_WRITE = 0x40000000,
            OPEN_EXISTING = 3,
            FILE_FLAG_WRITE_THROUGH = 0x80000000,
            FILE_FLAG_NO_BUFFERING = 0x20000000,
            PIPE_NOWAIT = ffi.new("unsigned long[1]", 0x00000001),

            INVALID_HANDLE_VALUE = ffi.cast("void*", -1),

            -- don't care about how many bytes WriteFile wrote, so allocate something to store the result once
            _lpNumberOfBytesWritten = ffi.new("unsigned long[1]"),
        }
        -- cache flags used in run() to avoid bor() call
        winapi._createfile_pipe_flags = winapi.bit.bor(winapi.FILE_FLAG_WRITE_THROUGH, winapi.FILE_FLAG_NO_BUFFERING)

        ffi.cdef[[
            void* __stdcall CreateFileA(const char *lpFileName, unsigned long dwDesiredAccess, unsigned long dwShareMode, void *lpSecurityAttributes, unsigned long dwCreationDisposition, unsigned long dwFlagsAndAttributes, void *hTemplateFile);
            bool __stdcall WriteFile(void *hFile, const void *lpBuffer, unsigned long nNumberOfBytesToWrite, unsigned long *lpNumberOfBytesWritten, void *lpOverlapped);
            bool __stdcall CloseHandle(void *hObject);
            bool __stdcall SetNamedPipeHandleState(void *hNamedPipe, unsigned long *lpMode, unsigned long *lpMaxCollectionCount, unsigned long *lpCollectDataTimeout);
        ]]
    else
        options.use_lua_io = false
    end
end

local spawned = false
local network = false
local disabled = false

local x = nil
local y = nil
local last_x = x
local last_y = y

local last_seek_time = nil

local effective_w = options.max_width
local effective_h = options.max_height
local real_w = nil
local real_h = nil

local script_name = nil

local show_thumbnail = false

local file_timer = nil
local file_check_period = 1/60
local first_file = false

local client_script = [=[
#!/bin/bash
MPV_IPC_FD=0; MPV_IPC_PATH="%s"
trap "kill 0" EXIT
while [[ $# -ne 0 ]]; do case $1 in --mpv-ipc-fd=*) MPV_IPC_FD=${1/--mpv-ipc-fd=/} ;; esac; shift; done
if echo "print-text test" >&"$MPV_IPC_FD"; then echo -n > "$MPV_IPC_PATH"; tail -f "$MPV_IPC_PATH" >&"$MPV_IPC_FD" & while read -r -u "$MPV_IPC_FD"; do :; done; fi
]=]

local function get_os()
    local raw_os_name = ""

    if jit and jit.os and jit.arch then
        raw_os_name = jit.os
    else
        if package.config:sub(1,1) == "\\" then
            -- Windows
            local env_OS = os.getenv("OS")
            if env_OS then
                raw_os_name = env_OS
            end
        else
            raw_os_name = mp.command_native({name = "subprocess", playback_only = false, capture_stdout = true, args = {"uname", "-s"}}).stdout
        end
    end

    raw_os_name = (raw_os_name):lower()

    local os_patterns = {
        ["windows"] = "Windows",

        ["linux"]   = "Linux",

        ["osx"]     = "Mac",
        ["mac"]     = "Mac",
        ["darwin"]  = "Mac",

        ["^mingw"]  = "Windows",
        ["^cygwin"] = "Windows",

        ["bsd$"]    = "Mac",
        ["sunos"]   = "Mac"
    }

    -- Default to linux
    local str_os_name = "Linux"

    for pattern, name in pairs(os_patterns) do
        if raw_os_name:match(pattern) then
            str_os_name = name
            break
        end
    end

    return str_os_name
end

local os_name = get_os()

if options.socket == "" then
    if os_name == "Windows" then
        options.socket = "thumbfast"
    else
        options.socket = "/tmp/thumbfast"
    end
end

if options.tnpath == "" then
    if os_name == "Windows" then
        options.tnpath = os.getenv("TEMP").."\\thumbfast.out"
    else
        options.tnpath = "/tmp/thumbfast.out"
    end
end

local unique = mp.get_property_native("pid")

options.socket = options.socket .. unique
options.tnpath = options.tnpath .. unique

local mpv_path = "mpv"

if os_name == "Mac" and unique then
    mpv_path = string.gsub(mp.command_native({name = "subprocess", playback_only = false, capture_stdout = true, args = {"ps", "-o", "comm=", "-p", tostring(unique)}}).stdout, "[\n\r]", "")
end

local function calc_dimensions()
    local width = mp.get_property_number("video-out-params/dw")
    local height = mp.get_property_number("video-out-params/dh")
    if not width or not height then return end

    local scale = mp.get_property_number("display-hidpi-scale", 1)

    if width / height > options.max_width / options.max_height then
        effective_w = math.floor(options.max_width * scale + 0.5)
        effective_h = math.floor(height / width * effective_w + 0.5)
    else
        effective_h = math.floor(options.max_height * scale + 0.5)
        effective_w = math.floor(width / height * effective_h + 0.5)
    end
end

local function info(w, h)
    local display_w, display_h = w, h

    local json, err = mp.utils.format_json({width=display_w, height=display_h, disabled=disabled, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
    mp.commandv("script-message", "thumbfast-info", json)
end

local function remove_thumbnail_files()
    os.remove(options.tnpath)
    os.remove(options.tnpath..".bgra")
end

local function spawn(time)
    if disabled then return end

    local path = mp.get_property("path")
    if path == nil then return end

    local open_filename = mp.get_property("stream-open-filename")
    local ytdl = open_filename and network and path ~= open_filename
    if ytdl then
        path = open_filename
    end

    remove_thumbnail_files()

    local args = {
        mpv_path, path, "--config=no", "--terminal=no", "--msg-level=all=no", "--idle=yes", "--keep-open=always","--pause=yes", "--ao=null", "--vo=null",
        "--load-auto-profiles=no", "--load-osd-console=no", "--load-stats-overlay=no", "--osc=no",
        "--vd-lavc-skiploopfilter=all", "--vd-lavc-skipidct=all", "--vd-lavc-software-fallback=1", "--vd-lavc-fast", "--vd-lavc-threads=2", "--hwdec="..(options.hwdec and "auto" or "no"),
        "--edition="..(mp.get_property_number("edition") or "auto"), "--vid="..(mp.get_property_number("vid") or "auto"), "--sub=no", "--audio=no", "--sub-auto=no", "--audio-file-auto=no",
        "--input-ipc-server="..options.socket,
        "--start="..time,
        "--ytdl-format=worst", "--demuxer-readahead-secs=0", "--demuxer-max-bytes=128KiB",
        "--gpu-dumb-mode=yes", "--tone-mapping=clip", "--hdr-compute-peak=no",
        "--sws-scaler=point", "--sws-fast=yes", "--sws-allow-zimg=no",
        "--audio-pitch-correction=no",
        "--vf=".."scale=w="..effective_w..":h="..effective_h..":flags=neighbor,format=bgra",
        "--ovc=rawvideo", "--of=image2", "--ofopts=update=1", "--ocopy-metadata=no", "--o="..options.tnpath
    }

    if os_name == "Windows" then
        table.insert(args, "--input-ipc-server="..options.socket)
    else
        local client_script_path = options.socket..".run"
        local file = io.open(client_script_path, "w+")
        if file == nil then
            mp.msg.error("client script write failed.")
            return
        else
            file:write(string.format(client_script, options.socket))
            file:close()
            mp.command_native_async({name = "subprocess", playback_only = true, args = {"chmod", "+x", client_script_path}}, function() end)
            table.insert(args, "--script="..client_script_path)
        end
    end

    spawned = true

    mp.command_native_async(
        {name = "subprocess", playback_only = true, args = args},
        function(success, result)
            if success == false or result.status ~= 0 then
                mp.msg.error("mpv subprocess create failed.")
            end
            spawned = false
        end
    )
end

local function run(command)
    if not spawned then return end

    if options.use_lua_io and os_name == "Windows" then
        local hPipe = winapi.C.CreateFileA("\\\\.\\pipe\\" .. options.socket, winapi.GENERIC_WRITE, 0, nil, winapi.OPEN_EXISTING, winapi._createfile_pipe_flags, nil)
        if hPipe ~= winapi.INVALID_HANDLE_VALUE then
            local buf = command .. "\n"
            winapi.C.SetNamedPipeHandleState(hPipe, winapi.PIPE_NOWAIT, nil, nil)
            winapi.C.WriteFile(hPipe, buf, #buf + 1, winapi._lpNumberOfBytesWritten, nil)
            winapi.C.CloseHandle(hPipe)
        end

        return
    end

    local file = nil
    if os_name == "Windows" then
        file = io.open("\\\\.\\pipe\\"..options.socket, "r+")
    else
        file = io.open(options.socket, "r+")
    end
    if file ~= nil then
        file:seek("end")
        file:write(command.."\n")
        file:close()
    end
end

local function draw(w, h, script)
    if not w or not show_thumbnail then return end
    local display_w, display_h = w, h

    if x ~= nil then
        mp.command_native(
            {name = "overlay-add", id=options.overlay_id, x=x, y=y, file=options.tnpath..".bgra", offset=0, fmt="bgra", w=display_w, h=display_h, stride=(4*display_w)}
        )
    elseif script then
        local json, err = mp.utils.format_json({width=display_w, height=display_h, x=x, y=y, socket=options.socket, tnpath=options.tnpath, overlay_id=options.overlay_id})
        mp.commandv("script-message-to", script, "thumbfast-render", json)
    end
end

local function real_res(req_w, req_h, filesize)
    local count = filesize / 4
    local diff = (req_w * req_h) - count

    if diff == 0 then
        return req_w, req_h
    else
        local threshold = 5 -- throw out results that change too much
        local long_side, short_side = req_w, req_h
        if req_h > req_w then
            long_side, short_side = req_h, req_w
        end
        for a = short_side, short_side - threshold, -1 do
            if count % a == 0 then
                local b = count / a
                if long_side - b < threshold then
                    if req_h < req_w then return b, a else return a, b end
                end
            end
        end
        return nil
    end
end

local function move_file(from, to)
    if os_name == "Windows" then
        os.remove(to)
    end
    -- move the file because it can get overwritten while overlay-add is reading it, and crash the player
    os.rename(from, to)
end

local function seek(fast)
    if last_seek_time then
        if options.precise == true then run("async seek " .. last_seek_time .. " absolute+exact")
        elseif options.precise == false then run("async seek " .. last_seek_time .. " absolute+keyframes")
        elseif options.precise == "auto" then
            run("async seek " .. last_seek_time .. (fast and " absolute+keyframes" or " absolute+exact"))
        end
    end
end

local seek_period = options.frequency
local seek_period_counter = 0
local seek_timer
seek_timer = mp.add_periodic_timer(seek_period, function()
    if seek_period_counter == 0 then
        seek(true)
        seek_period_counter = 1
    else
        if seek_period_counter == 2 then
            seek_timer:kill()
            seek()
        else seek_period_counter = seek_period_counter + 1 end
    end
end)
seek_timer:kill()

local function request_seek()
    if seek_timer:is_enabled() then
        seek_period_counter = 0
    else
        seek_timer:resume()
        seek(true)
        seek_period_counter = 1
    end
end

local function check_new_thumb()
    -- the slave might start writing to the file after checking existance and
    -- validity but before actually moving the file, so move to a temporary
    -- location before validity check to make sure everything stays consistant
    -- and valid thumbnails don't get overwritten by invalid ones
    local tmp = options.tnpath..".tmp"
    move_file(options.tnpath, tmp)
    local finfo = mp.utils.file_info(tmp)
    if not finfo then return false end
    if first_file then
        request_seek()
        first_file = false
    end
    local w, h = real_res(effective_w, effective_h, finfo.size)
    if w then -- only accept valid thumbnails
        move_file(tmp, options.tnpath..".bgra")

        real_w, real_h = w, h
        if real_w then info(real_w, real_h) end
        return true
    end
    return false
end

file_timer = mp.add_periodic_timer(file_check_period, function()
    if check_new_thumb() then
        draw(real_w, real_h, script_name)
    end
end)
file_timer:kill()

local function thumb(time, r_x, r_y, script)
    if disabled then return end

    time = tonumber(time)
    if time == nil then return end

    if r_x == "" or r_y == "" then
        x, y = nil, nil
    else
        x, y = math.floor(r_x + 0.5), math.floor(r_y + 0.5)
    end

    script_name = script
    if last_x ~= x or last_y ~= y or not show_thumbnail then
        show_thumbnail = true
        last_x = x
        last_y = y
        draw(real_w, real_h, script)
    end

    if time == last_seek_time then return end
    last_seek_time = time
    if not spawned then spawn(time) end
    request_seek()
    if not file_timer:is_enabled() then file_timer:resume() end
end

local function clear()
    file_timer:kill()
    seek_timer:kill()
    last_seek = 0
    show_thumbnail = false
    last_x = nil
    last_y = nil
    if script_name then return end
    mp.command_native(
        {name = "overlay-remove", id=options.overlay_id}
    )
end

local function watch_changes()
    local old_w = effective_w
    local old_h = effective_h

    calc_dimensions()

    if spawned then
        if old_w ~= effective_w or old_h ~= effective_h then
            -- mpv doesn't allow us to change output size
            run("quit")
            clear()
            info(effective_w, effective_h)
            spawned = false
            spawn(last_seek_time or mp.get_property_number("time-pos", 0))
        end
    else
        if old_w ~= effective_w or old_h ~= effective_h then
            info(effective_w, effective_h)
        end
    end
end

local function sync_changes(prop, val)
    if spawned and val then
        run("set "..prop.." "..val)
    end
end

local function file_load()
    clear()
    real_w, real_h = nil, nil
    last_seek_time = nil

    network = mp.get_property_bool("demuxer-via-network", false)
    local image = mp.get_property_native("current-tracks/video/image", true)
    local albumart = image and mp.get_property_native("current-tracks/video/albumart", false)
    local short_video = mp.get_property_native("duration", 0) <= options.min_duration

    disabled = (network and not options.network) or (albumart and not options.audio) or (image and not albumart) or (short_video and options.min_duration > 0)
    calc_dimensions()
    info(effective_w, effective_h)
    if disabled then return end

    spawned = false
    if options.spawn_first then
        spawn(mp.get_property_number("time-pos", 0))
        first_file = true
    end
end

local function shutdown()
    run("quit")
    remove_thumbnail_files()
    if os_name ~= "Windows" then
        os.remove(options.socket)
        os.remove(options.socket..".run")
    end
end

mp.observe_property("display-hidpi-scale", "native", watch_changes)
mp.observe_property("video-out-params", "native", watch_changes)
mp.observe_property("vid", "native", sync_changes)
mp.observe_property("edition", "native", sync_changes)

mp.register_script_message("thumb", thumb)
mp.register_script_message("clear", clear)

mp.register_event("file-loaded", file_load)
mp.register_event("shutdown", shutdown)
