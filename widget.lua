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

local contains = function(item, tb)
	for _, value in ipairs(tb) do
		if item == value then
			return true
		end
	end
	return false
end

---@class Widget: wibox.widget
local Widget = {}
Widget.__index = Widget

---@generic T
---@param self T
---@param gobject gears.object  | Binding
---@param ... string | fun(T, ...:any): nil
---@return T
Widget.hook = function(self, gobject, ...)
	local args = { ... }

	---@type fun(T, ...:any): nil
	local callback
	---@type string
	local signal

	if type(args[1]) == "function" and type(args[2]) == "nil" then
		signal = "property::value"
		callback = args[1]
	elseif type(args[1] == "function") and type(args[2]) == "string" then
		error("Please use Widget:hook(gobject, signal, callback), not Widget:hook(gobject, callback, signal)")
		return self
	else
		signal = args[1]
		callback = args[2]
	end

	signal = string.gsub(signal, "_", "-")

	-- local on_disconnect
	-- on_disconnect = function()
	-- 	gobject:disconnect_signal(signal, callback)
	-- 	gobject:disconnect_signal("destroy", on_disconnect)
	-- end

	if contains(gobject, {
		awesome,
		client,
		screen,
		tag,
		mouse,
		root,
	}) then
		gobject.connect_signal(signal, callback)
	else
		gobject:connect_signal(signal, callback)
	end
	--gobject:connect_signal("destroy", on_disconnect)

	idle(function()
		callback(self)
	end)

	return self
end

---@generic T
---@param self T
---@param self_prop string
---@param gobject gears.object | Binding
---@param gobject_prop? string
---@param fn? fun(v: any): any
---@return T
Widget.bind = function(self, self_prop, gobject, gobject_prop, fn)
	gobject_prop = gobject_prop or "value"

	fn = fn or function(v)
		return v
	end

	return self:hook(gobject, "property::" .. gobject_prop, function()
		self[self_prop] = fn(gobject[gobject_prop])
	end)
end

---@generic T
---@param args
---| table
---| { widget : T}
---| { on_hover: fun(self: T, on_hoverlost: fun(self: T)), on_press: fun(self: T), on_release: fun(self: T), setup: fun(self: T): nil}
---@return T | Widget
Widget.new = function(args)
	local new_widget = { widget = args.widget, layout = args.layout, fit = args.fit, draw = args.draw }

	args.widget, args.layout, args.fit, args.draw = nil, nil, nil, nil
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

	for key, value in pairs(args) do
		local value_type = type(value)
		if value_type == "table" then -- childrens / widget / binding
			if value.transform_fn then -- binding
				new_widget:bind(key, value.emitter, value.prop, value.transform_fn)
			elseif value.widget or value.layout or value.children then
				if value.connect_signal then -- already a widget / layout
					children[#children + 1] = value
				else
					children[#children + 1] = Widget.new(value)
				end
			else -- children
				new_widget[key] = value
			end
		elseif key == "on_hover" then
			new_widget:connect_signal("mouse::enter", value)
		elseif key == "on_hoverlost" then
			new_widget:connect_signal("mouse::leave", value)
		elseif key == "on_click" then
			new_widget:connect_signal("button::press", value)
		elseif key == "on_release" then
			new_widget:connect_signal("button::release", value)
		else
			new_widget[key] = value
		end
	end

	new_widget.children = children
	args.setup(new_widget)

	return new_widget
end

return Widget
