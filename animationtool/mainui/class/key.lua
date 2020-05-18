module = {
    selected = 1,
    transformsHasRefreshed = false,
    transformsDefault = {

    },
    frames = {
        
    },
    targetID = nil
}
require(lp("json.lua"))

function module:frameDefault()
    return {
        transforms = {

        },
        wait = 0.1,
        animationState = {},
        lights = {},
        burstParticle = jarray(),
        fireEvents = jarray(),
        playSounds = jarray()
    }
end
function module:reset() --starts from zero
    self.frames = {}
    self.frames[1] = self.frameDefault()
    self:select(1)
end
function module:validate(frames) --bake keys prevents unusual values
    local s = frames or copycat(self.frames)
    local s2 = {}

    for _,frame in ipairs(s) do
        local newframe = self:frameDefault()

        for trname,transform in pairs(frame.transforms or {}) do
            newframe.transforms[trname] = {}
            
            for varname, value in pairs(transform) do
                if self.transformsDefault[trname] and self.transformsDefault[trname][varname] then
                    if not self:equal(self.transformsDefault[trname][varname], value) then
                        newframe.transforms[trname][varname] = value
                    end
                end
            end

        end
        newframe.playSounds = copycat(frame.playSounds or jarray())
        newframe.animationState = copycat(frame.animationState or {})
        newframe.burstParticle = copycat(frame.burstParticle or jarray())
        newframe.lights = copycat(frame.lights or {})
        newframe.fireEvents = copycat(frame.fireEvents or jarray())
        newframe.wait = copycat(frame.wait or 0.1)
        --insert valid frame
        table.insert(s2, newframe)
    end

    return s2
end

function module:equal(a,b) --do not use this for complex compaire tables
    if type(a) == type(b) then
        if type(a) == "table" and #a == 2 and #b== 2 then
            if a[1] == b[1] and a[2] == b[2] then
                return true
            end
        elseif type(a) == "number" then
            if a == b then
                return true
            end
        elseif type(a) == "boolean" then
            return a == b
        else
            return false
        end
    end
    return false
end

--events

propertiesWidgetEnum1 = {
    soundsInput     = "playSounds",
    stateInput      = "animationState",
    particleInput   = "burstParticle",
    lightsInput     = "lights",
    eventsInput     = "fireEvents",
    waitInput     = "wait",
}

function module:propertiesProcess(wid)
    local input = widget.getText(wid)
    if not input then return false end
	local a, e = pcall(json.decode, input)
	if a then
        if type(e) == type(self.frames[self.selected][propertiesWidgetEnum1[wid]]) then
            self.frames[self.selected][propertiesWidgetEnum1[wid]] = e
            return true
		end
    end
    return false
end

function module:propertiesChanged(wid)
    if wid then
        if not self:propertiesProcess(wid) then
            widget.setFontColor(wid, {255,0,0,255})
        else
            widget.setFontColor(wid, {255,255,255,255})
        end
    end
end


function getWholeTransformConfig()
	local item = {}
	local handItem = world.entityHandItemDescriptor(player.id(), "primary")
    local handAltItem = world.entityHandItemDescriptor(player.id(), "alt")
    if not handItem and handAltItem then
        handItem = handAltItem
    end
	if handItem then
		local itemConfig = root.itemConfig(handItem)
		local item2 = sb.jsonMerge(itemConfig.config, itemConfig.parameters)
        local animationConfig = item2.animation
        if type(animationConfig) == "string" then
            animationConfig = root.assetJson(dir(animationConfig, itemConfig.directory))
        end
        local animationFinal = sb.jsonMerge(animationConfig or {}, item2.animationCustom or {})
		local animationFinalFinal = sb.jsonMerge(animationFinal, handItem.parameters.animationCustom or {})
		item = animationFinalFinal
	end
	return item
end

function module:emptyNil(tab) -- turns empty tables into nil
    for i,v in pairs(tab) do
        return tab
    end
    return nil
end

function module:wholeDefaultTransformationGroups()
    local transformationGroups = {}
    for i,v in pairs(self.transformsDefault) do
        transformationGroups[i] = {}
        transformationGroups[i].transform = v
    end
    return transformationGroups
end

function module:copyTransform()
	local uiConfig = root.assetJson("/animationtool/clipboardui/pane.json", {})
	if self.frames[self.selected] then
		local transforms = getWholeTransformConfig().transformationGroups or self:wholeDefaultTransformationGroups()
		for i,v in pairs(self.frames[self.selected].transforms) do
			if transforms[i] then
                transforms[i].transform = sb.jsonMerge(transforms[i].transform or {}, self.frames[self.selected].transforms[i] or {})
            else
                transforms[i] = {ignore = true, transform = sb.jsonMerge({}, self.frames[self.selected].transforms[i] or {})} -- assume if its controlled by a script
            end
		end
		uiConfig.clipboard = sb.printJson(transforms,0)
		player.interact("ScriptPane", uiConfig)
	end
end


function module:selectChanged()
    local currentFrame = self.frames[self.selected]
    widget.setText("status2", "Key:"..self.selected.." of "..#self.frames)
    widget.setText("soundsInput", sb.printJson(currentFrame.playSounds, 0))
    widget.setText("stateInput", sb.printJson(currentFrame.animationState, 0))
    widget.setText("particleInput", sb.printJson(currentFrame.burstParticle, 0))
    widget.setText("lightsInput", sb.printJson(currentFrame.lights, 0))
    widget.setText("eventsInput", sb.printJson(currentFrame.fireEvents, 0))
    widget.setText("waitInput", sb.printJson(currentFrame.wait, 0))

    self:propertiesChanged("soundsInput")
    self:propertiesChanged("stateInput")
    self:propertiesChanged("particleInput")
    self:propertiesChanged("lightsInput")
    self:propertiesChanged("eventsInput")
    self:propertiesChanged("waitInput")
end

--save and load

function module:save()
    widget.setText("animationInput",sb.printJson(self:validate(), 0))
end

function module:load()
    if not self.transformsHasRefreshed then return end 
    local input = widget.getText("animationInput")
    local a,e = pcall(json.decode, input)
    if a then
        self.frames = self:validate(e or {})
        if #self.frames > 0 then
            self:select(1)
            widget.setText("animationInput", "")
        else
            self:reset()
        end
    end
end

--callbacks

function module:init()
    self.targetID = player.id()
    self:reset()
    --widget binds
    widgetBind("soundsInput", function() self:propertiesChanged("soundsInput") end )
    widgetBind("waitInput", function() self:propertiesChanged("waitInput") end )
    widgetBind("stateInput", function() self:propertiesChanged("stateInput") end )
    widgetBind("particleInput", function() self:propertiesChanged("particleInput") end )
    widgetBind("lightsInput", function() self:propertiesChanged("lightsInput") end )
    widgetBind("eventsInput", function() self:propertiesChanged("eventsInput") end )
    
    widgetBind("next", function() self:next() end )
    widgetBind("previous", function() self:previous() end )
    widgetBind("delete", function() self:remove() end )
    widgetBind("add", function() self:add() end )
    widgetBind("save", function() self:save() end )
    widgetBind("load", function() self:load() end )

    widgetBind("copytransform", function() self:copyTransform() end )
    --
    --widgetBind("copyy", function() self:add() end )
    --widgetBind("paste", function() self:add() end )

end

function module:update()

end

function module:uninit()

end

--key indexing
function module:indexClamp(n)
    return math.min(math.max(n,1), math.max(#self.frames, 1))
end

function module:key(index)
    if not index then
        index = self.selected
    end
    return self.frames[self:indexClamp(index)]
end

function module:select(index)
    self.selected = self:indexClamp(index)
    self:selectChanged()
end

--key remove or add

function module:add(index, frame)
    if not index then index = self.selected end
    if not frame then frame = self:frameDefault() end
    table.insert(self.frames, index+1, frame)
    self:select(index+1)
end

function module:remove(index)
    if not index then index = self.selected end
    if #self.frames == 1 then
        self:reset()
        return
    end
    
    table.remove(self.frames, index)
    self:select(index)
end

--also key indexing but for buttons

function module:next()
    self:select(self.selected + 1)
end

function module:previous()
    self:select(self.selected - 1)
end

--transform editiing

function module:getCurrentKeyTransform(tr, val)
    return (self.frames[self.selected].transforms or self.transformsDefault[tr])
end

function module:getCurrentKeyTransformValue(tr, val)
    return (self.frames[self.selected].transforms[tr] or self.transformsDefault[tr])[val] or self.transformsDefault[tr][val]
end

function module:setCurrentKeyTransformValue(tr, val, var)
    if not self.frames[self.selected].transforms[tr] then
        self.frames[self.selected].transforms[tr] = {}
    end

    self.frames[self.selected].transforms[tr][val] = var
end
