local gears = require("gears")

local Binding = require("awful-less.binding")

---@class Service
local Service = {}

---Transform a gears.object into a Service, with a bind() method
---@generic T
---@param object T | gears.object
---@return T | { bind: fun(self, prop: string): Binding  }
Service.new = function(object)
	if object.emit_signal then
		---@return Binding
		object.bind = function(self, prop)
			return Binding.new(self, prop)
		end
		return object
	else
		return Service.new(gears.object({
			class = setmetatable({}, { __index = object }),
			enable_properties = true,
			enable_auto_signals = true,
		}))
	end
end

---Turn a GObject.Object into a gears.object
---@generic T
---@param object GObject.Object | T
---@return GObject.Object | T | Service
Service.gearsify = function(object)
	local new_gobject = gears.object({})

	new_gobject._class = object

	new_gobject._class.on_notify = function(self, signal)
		return new_gobject:emit_signal("property::" .. signal:get_name(), self[signal:get_name()])
	end

	setmetatable(new_gobject, {
		__index = function(mt, key)
			if key == "get_class" or key == "class" then
				return mt._class
			end

			local method_value = gears.object[key]
			if method_value then
				return method_value
			end

			method_value = mt._class[key]

			if method_value then
				if type(method_value) == "userdata" then
					return function(_, ...)
						return method_value(mt._class, ...)
					end
				else
					return method_value
				end
			end
		end,
	})

	return Service.new(new_gobject)
end

return Service
