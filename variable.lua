local gears = require("gears")

local Binding = require("awful-less.binding")

---@class Variable: gears.object
---@field value any
---@field private _value any
---@field new fun(value: any): Variable
local Variable = {}

---@param value any
---@return Variable
Variable.new = function(value)
	local self = gears.object({
		enable_properties = true,
		class = setmetatable({}, {
			__index = Variable,
			__call = function(mt)
				return mt:bind()
			end,
		}),
	})
	self.value = value

	return self
end

Variable.get_value = function(self)
	return self._value
end

---@param new_value any
---@return nil
Variable.set_value = function(self, new_value)
	if self.value == new_value then
		return
	end

	self._value = new_value

	return self:emit_signal("property::value", self._value)
end

-- ---@return nil
-- Variable.destroy = function(self)
-- 	return self:emit_signal("destroy")
-- end

---@return Binding
Variable.bind = function(self)
	return Binding.new(self, "value")
end

return Variable
