local wibox = require("wibox")
local awful = require("awful")

-- Battery widget
battery = wibox.widget.textbox()

function getBatteryStatus()
    local fd= io.popen("battery")
    local status = fd:read()
    fd:close()
    return status
end

batteryTimer = timer({timeout = 30})
batteryTimer:connect_signal("timeout", function()
    battery:set_markup(getBatteryStatus())
end)
batteryTimer:start()
battery:set_markup(getBatteryStatus())

-- Volume widget
volume_widget = wibox.widget.textbox()
volume_widget:set_align("right")

function update_volume(widget)
    local fd = io.popen("amixer sget Master")
    local status = fd:read("*all")
    fd:close()

    -- local volume = tonumber(string.match(status, "(%d?%d?%d)%%")) / 100
    local volume = string.match(status, "(%d?%d?%d)%%")
    volume = string.format("% 3d", volume)

    status = string.match(status, "%[(o[^%]]*)%]")

    if string.find(status, "on", 1, true) then
        -- For the volume numbers
        volume = volume .. "%"
    else
        -- For the mute button
        volume = volume .. "M"
    end

    widget:set_markup(volume)
end

update_volume(volume_widget)

mytimer = timer({ timeout = 1 })
mytimer:connect_signal("timeout", function () update_volume(volume_widget) end)
mytimer:start()
