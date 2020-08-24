module = {
    defaultValues = {
        curve = 1
    },
    mouse1 = false,
    editing = {
        type = "nil",
        transform = false,
        value = false
    },
    canvas = false

}

function module:init()
    self.canvas = widget.bindCanvas("canvas")
    bindMouseHandler(function(position, button, down) self:handleMouse(position, button, down) end)
end

require "/scripts/vec2.lua"

function module:update()
    if self.editing.transform and self.editing.value and key.transformsDefault and key.transformsDefault[self.editing.transform] and key.transformsDefault[self.editing.transform][self.editing.value] then
        local changes = {0,0}
        if type(self.mouse1) == "table" and self.canvas then
            changes = vec2.sub(self.canvas:mousePosition(), self.mouse1.ePos)
            self.mouse1.ePos = self.canvas:mousePosition()
        end
        self:adds(changes)

        self:visualize()
    end
end

function module:adds(pos)
        local var1 = key:getCurrentKeyTransformValue(self.editing.transform,self.editing.value)
        if type(var1) == "number" and pos[1] ~= 0 then
            key:setCurrentKeyTransformValue(self.editing.transform,self.editing.value, var1 + (pos[1] * 0.0625))
        elseif type(var1) == "table" and (pos[1] ~= 0 or pos[2] ~= 0) then
            key:setCurrentKeyTransformValue(self.editing.transform,self.editing.value, vec2.add(var1, vec2.mul(pos, 0.0625)))
        end
end

function module:resetValue()
    if self.editing.transform and self.editing.value and key.transformsDefault[self.editing.transform][self.editing.value] then
        local var1 = key:getCurrentKeyTransformValue(self.editing.transform,self.editing.value)
        local defaultval = key.transformsDefault[self.editing.transform][self.editing.value]
        if type(var1) == "number" then
            key:setCurrentKeyTransformValue(self.editing.transform,self.editing.value, defaultval)
        elseif type(var1) == "table" then
            key:setCurrentKeyTransformValue(self.editing.transform,self.editing.value, defaultval)
        end
    end
end

function module:uninit()
    
end

function module:handleMouse(position, button, down)
    if self.editing.transform and self.editing.value and key.transformsDefault[self.editing.transform][self.editing.value] then
        if button == 0 and not down then
            self.mouse1 = false
        elseif button == 0 then
            self.mouse1 = {sPos = position, ePos = position}
        elseif button == 1 and down then
            self:resetValue()
        end
    end
end


function module:setEditing(tr, val)
    if not val then return end
    self.editing.transform = tr
    self.editing.value = val

end

function module:wrapAround(x, min, max)
    if x > max then
        return max - (min - x) % (max - min)
    elseif x < min then
        return min + (x - min) % (max - min)
    else
        return x
    end
end

function module:visualize()
    self.canvas:clear()
    if not self.canvas then return end
    if self.editing.transform and self.editing.value and key.transformsDefault[self.editing.transform][self.editing.value] then
        local var1 = key:getCurrentKeyTransformValue(self.editing.transform,self.editing.value)
        local size = self.canvas:size()
        self.canvas:drawText(
            sb.printJson(var1, 0), {
                position = {0,0},
                horizontalAnchor = "left",
                verticalAnchor = "bottom"
            }, 
            7,
            "white"
        )
        if type(var1) == "table" and #var1 == 2 then
            local var2 = copycat(var1)
            var2[1] = self:wrapAround(var2[1],  -(size[1] / 16), size[1] / 16)
            var2[2] = self:wrapAround(var2[2],  -(size[2] / 16), size[2] / 16)

            self.canvas:drawLine(
                {var2[1] * 8 + math.floor(size[1] / 2), 0},
                {var2[1] * 8 + math.floor(size[1] / 2), size[2]},
                
                {255,255,255,255 - 64}, 
                1
            )
            self.canvas:drawLine(
                {0		, var2[2] * 8 + math.floor(size[2] / 2)},
                {size[1], var2[2] * 8 + math.floor(size[2] / 2)},
                
                {255,255,255,255 - 64}, 
                1
            )
        elseif type(var1) == "number" then
            var1 = self:wrapAround(var1,  -(size[1] / 16), size[1] / 16)
            self.canvas:drawLine(
                {var1 * 8 + math.floor(size[1] / 2), 0},
                {var1 * 8 + math.floor(size[1] / 2), size[2]},
                
                {255,255,255,255 - 64}, 
                1
            )
        end
    end

end