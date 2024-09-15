local awful = require("awful")
---@type wibox
local wibox = require("wibox")
local GLib = require("lgi").require("GLib", "2.0")

---@param callback function
---@return integer
local idle = function(callback)
	return GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, function()
		callback()
	end)
end

---@class Widget: wibox.widget
local Widget = {}
Widget.__index = Widget

---@param gobject gears.object | Binding
---@param callback fun(self, ...:any)
---@param signal string
---@return self
Widget.hook = function(self, gobject, callback, signal)
	signal = string.gsub(signal, "_", "-")

	-- local on_disconnect
	-- on_disconnect = function()
	-- 	gobject:disconnect_signal(signal, callback)
	-- 	gobject:disconnect_signal("destroy", on_disconnect)
	-- end

	gobject:connect_signal(signal, callback)
	--gobject:connect_signal("destroy", on_disconnect)

	idle(function()
		callback(self)
	end)

	return self
end

---@param prop string
---@param gobject gears.object | Binding
---@param gobject_prop? string
---@param fn? fun(v: any): any
---@return self
Widget.bind = function(self, prop, gobject, gobject_prop, fn)
	gobject_prop = gobject_prop or "value"

	fn = fn or function(v)
		return v
	end

	return self:hook(gobject, function()
		self[prop] = fn(gobject[gobject_prop])
	end, "property::" .. gobject_prop)
end

---@param args table | { on_hover: fun(self: wibox.widget, on_hoverlost: fun(self: wibox.widget)), on_press: fun(self: wibox.widget), on_release: fun(self: wibox.widget), setup: fun(self: wibox.widget): nil}
---@return wibox.widget | Widget
Widget.new = function(args)
	local new_widget = { widget = args.widget, layout = args.layout }
	args.widget, args.layout = nil, nil
	args.setup = args.setup or function() end

	for key, value in pairs(args) do
		if string.match(key, "^[gs]et_") then
			new_widget[key] = value
		end
	end

	new_widget = wibox.widget(new_widget)

	new_widget.hook = Widget.hook
	new_widget.bind = Widget.bind

	local children = {}

	for index, value in next, args do
		local value_type = type(value)
		if value_type == "table" then
			if value.transform_fn then -- Binding
				new_widget:bind(index, value.emitter, value.prop, value.transform_fn)
			elseif value.widget or value.layout then -- widget / layout
				if value.connect_signal then -- already a widget
					children[#children + 1] = value
				else
					children[#children + 1] = Widget.new(value)
				end
			else
				new_widget[index] = value
			end
		elseif index == "on_hover" then
			new_widget:connect_signal("mouse::enter", value)
		elseif index == "on_hoverlost" then
			new_widget:connect_signal("mouse::leave", value)
		elseif index == "on_click" then
			new_widget:connect_signal("button::press", value)
		elseif index == "on_release" then
			new_widget:connect_signal("buton::release", value)
		else
			new_widget[index] = value
		end
	end

	new_widget.children = children
	args.setup(new_widget)

	return new_widget
end

return Widget
