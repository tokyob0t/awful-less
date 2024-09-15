local gears = require("gears")

local map = function(t, func)
	local new_table = {}
	for key, value in pairs(t) do
		table.insert(new_table, func(value, key))
	end
	return new_table
end

---@class gears.object
---@field emit_signal fun(self: gears.object, name: string, ...: any) @Emit a notification signal.
---@field connect_signal fun(self: gears.object, name: string, func: function) @Connect to a signal.
---@field weak_connect_signal fun(self: gears.object, name: string, func: function) @Connect to a signal weakly. This allows the callback function to be garbage collected and automatically disconnects the signal when that happens. Warning: Only use this function if you really, really, really know what you are doing.
---@field disconnect_signal fun(self: gears.object, name: string, func: function) @Disconnect a signal from a source.

---@class Binding: gears.object
---@field transform_fn fun(v: any): any
---@field prop string
---@field emitter gears.object
---@field private _emitter gears.object
---@field private _prop string
---@field private _emitter gears.object
local Binding = {}

---@param emitter gears.object
---@param prop string
---@return Binding
Binding.new = function(emitter, prop)
	local self = gears.object({ enable_properties = true, class = setmetatable({}, { __index = Binding }) })
	rawset(self, "_prop", prop)
	rawset(self, "_emitter", emitter)

	self.transform_fn = function(v)
		return v
	end

	return self
end

---@param fn fun(v: any): any
---@return Binding
Binding.as = function(self, fn)
	local bind = Binding.new(self.emitter, self.prop)
	local old_fn = self.transform_fn

	bind.transform_fn = function(v)
		return fn(old_fn(v))
	end

	return bind
end

Binding.merge = function(bindings, fn)
	local Variable = require("awful-less.variable")
	local update = function()
		return fn(unpack(map(bindings, function(b)
			return b.transform_fn(b.emitter[b.prop])
		end)))
	end

	local watcher = Variable.new()

	for _, b in ipairs(bindings) do
		b.emitter:connect_signal("property::" .. string.gsub(b.prop, "_", "-"), function()
			watcher.value = update()
		end)
	end

	return watcher:bind()
end

Binding.set_emitter = function() end
Binding.get_emitter = function(self)
	return self._emitter
end

Binding.set_prop = function() end
Binding.get_prop = function(self)
	return self._prop
end

return Binding
