--[[
    Pictureframe – Background Audio Integration

    Integrates background audio control into mpv playback.

    Detects whether the current media is an image or video and notifies
    the background audio control script accordingly.

    Monitors changes to the background audio preference and synchronizes
    playback when the setting changes.

    Background audio is stopped when mpv shuts down.
]]

local CONTROL_SCRIPT =
    os.getenv("HOME") .. "/pictureframe/scripts/background-audio-control.sh"

local ENABLED_FILE =
    "/tmp/pictureframe-background-audio/enabled"

local last_enabled = nil

-- Executes a command through the background audio control script.
-- Logs command failures and informational output.
local function run_control(command)
    local result = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = { CONTROL_SCRIPT, command }
    })

    if result.status ~= 0 then
        mp.msg.error(
            "Background audio command failed: "
            .. command
            .. ": "
            .. (result.stderr or "")
        )
        return
    end

    if result.stdout ~= nil and result.stdout ~= "" then
        mp.msg.info(result.stdout:gsub("%s+$", ""))
    end
end

-- Determines whether the current media is an image.
-- Inspects the mpv track list to distinguish images from video.
local function is_image()
    local tracks = mp.get_property_native("track-list", {})

    local has_image = false
    local has_video = false

    for _, track in ipairs(tracks) do
        if track.type == "video" then
            if track.image == true then
                has_image = true
            else
                has_video = true
            end
        end
    end

    return has_image and not has_video
end

-- Reads the current background audio preference from the runtime state file.
-- Returns nil if the file cannot be opened.
local function read_enabled()
    local file = io.open(ENABLED_FILE, "r")

    if file == nil then
        return nil
    end

    local value = file:read("*l")
    file:close()

    return value
end

-- Notifies the background audio controller when new media is loaded.
-- Initializes the cached background audio preference.
mp.add_hook("on_preloaded", 50, function()
    if is_image() then
        run_control("image")
    else
        run_control("video")
    end

    last_enabled = read_enabled()
end)

-- Checks for changes to the background audio preference every second.
-- Synchronizes playback only when the preference has changed.
mp.add_periodic_timer(1.0, function()
    local enabled = read_enabled()

    if enabled ~= nil and enabled ~= last_enabled then
        last_enabled = enabled
        run_control("sync")
    end
end)

-- Notifies the background audio controller when mpv shuts down.
mp.register_event("shutdown", function()
    run_control("idle")
end)