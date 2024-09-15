# awful-less

ags-like thing for awm, making widget design less awful

### Installation

```sh
git clone https://github.com/tokyob0t/awful-less.git ~/.config/awesome/awful-less
```

### Usage

#### Widget

```lua
local wibox = require("wibox")
local Widget = require("awful-less.widget")
local Binding = require("awful-less.binding")
local Service = require("awful-less.service")

-- using AstalBattery for the battery service
-- https://aylur.github.io/astal/libraries/battery
-- Since Astal its a Gears.Object, we use Service.gearsify to transform it into a gears.object
local battery = Service.gearsify(require("lgi").require("AstalBattery").get_default())

local battery_percentage = Widget.new({
	widget = wibox.widget.textbox,
	valign = "center",
	text = battery:bind("percentage"):as(function(v)
		return string.format("%d%%", v * 100)
	end),
})
```
