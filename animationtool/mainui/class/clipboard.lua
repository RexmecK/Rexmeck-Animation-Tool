module = {
    set = {
        vec2 = {0,0},
        number = 0
    },
    frame = false,
    lastEditingType = "??"
}

function module:init()
    widgetBind("clipboard_input", function()self:textChanged()end)
    widgetBind("clipboard_paste", function()
        if editor.editing.transform and editor.editing.value and (key.transformsDefault[editor.editing.transform] or {})[editor.editing.value] then
            key:setCurrentKeyTransformValue(editor.editing.transform,editor.editing.value, copycat(self.set[self.lastEditingType]))
            self:changed(self.lastEditingType)
        end
    end)
    widgetBind("clipboard_copy", function()
        if editor.editing.transform and editor.editing.value and (key.transformsDefault[editor.editing.transform] or {})[editor.editing.value] then
            self:setText(sb.printJson(key:getCurrentKeyTransformValue(editor.editing.transform,editor.editing.value), 0))
            self:textChanged()
        end
    end)

    --frames
    widgetBind("copyy", function() self.frame = copycat(key.frames[key.selected]) end )
    widgetBind("paste", function() if not self.frame then return end key:add(key.selected, copycat(self.frame)) end )
end

function module:textChanged()
    local procJson = safeJson(self:getText())
    local currentType = type(procJson)
    local lastType = type(self.set[self.lastEditingType])
    if currentType == lastType then
        if currentType == "table" and #procJson == 2 and type(procJson[1]) == "number" and type(procJson[2]) == "number" then
            self.set["vec2"][1] = procJson[1]
            self.set["vec2"][2] = procJson[2]
            --self:changed("vec2")
        elseif currentType == "number" then
            self.set["number"] = procJson
            --self:changed("number")
        end
    else
        self:changed("nil")
    end
end

function module:setText(text)
    if widget.hasFocus("clipboard_input") then return end
    widget.setText("clipboard_input", text)
end

function module:getText(text)
    return widget.getText("clipboard_input")
end

function module:changed(type)
    if type == "nil" then
        widget.setFontColor("clipboard_input", {255,0,0,255})
    end
    if self.set[type] then
        self:setText(sb.printJson(self.set[type], 0))
        widget.setFontColor("clipboard_input", {255,255,255,255})
    else
        widget.setFontColor("clipboard_input", {255,0,0,255})
    end

end

function module:legacyType(a)
    local t = type(a)
    if t == "table" and #t == 2 then
        return "vec2"
    end
    return t
end

function module:update()
    if editor.editing.transform and editor.editing.value and key.transformsDefault[editor.editing.transform][editor.editing.value] and self:legacyType(key.transformsDefault[editor.editing.transform][editor.editing.value]) ~= self.lastEditingType then
        local val = key.transformsDefault[editor.editing.transform][editor.editing.value]
        local t = type(val)
        if t == "table" and #val == 2 then 
            self:changed("vec2")
            self.lastEditingType = "vec2"
        elseif  t == "number" then 
            self.lastEditingType = "number"
            self:changed("number")
        end
    end
end
