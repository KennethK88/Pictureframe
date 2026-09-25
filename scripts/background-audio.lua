local CONTROL_SCRIPT =
    os.getenv("HOME") .. "/pictureframe/scripts/background-audio-control.sh"

local ENABLED_FILE =
    "/tmp/pictureframe-background-audio/enabled"

local last_enabled = nil

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

local function read_enabled()
    local file = io.open(ENABLED_FILE, "r")

    if file == nil then
        return nil
    end

    local value = file:read("*l")
    file:close()

    return value
end

mp.add_hook("on_preloaded", 50, function()
    if is_image() then
        run_control("image")
    else
        run_control("video")
    end

    last_enabled = read_enabled()
end)

mp.add_periodic_timer(1.0, function()
    local enabled = read_enabled()

    if enabled ~= nil and enabled ~= last_enabled then
        last_enabled = enabled
        run_control("sync")
    end
end)

mp.register_event("shutdown", function()
    run_control("idle")
end)