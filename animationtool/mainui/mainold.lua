--messy here do not mod this. purposes prob need rewrites

require "/scripts/vec2.lua"
require "/animUI/json.lua"

function bindList(location)
	local newlist = {
		_ = {
			path = location,
			inlist = {}
		}
	}
	widget.clearListItems(location)
	function newlist:add(func)
		local newobj = widget.addListItem(self._.path)
		table.insert(self._.inlist, newobj)
		if func then
			widget.registerMemberCallback(self._.path.."."..newobj, "call_"..newobj, func)
		end
		return newobj
	end
	
	function newlist:removeSelected()
		local str = widget.getListSelected(self._.path)
		if not str then return false end
		self:remove(str)
		return true
	end
	
	function newlist:select(str)
		widget.setListSelected(self._.path, str)
	end
	function newlist:selected()
		return widget.getListSelected(self._.path)
	end
	
	function newlist:remove(str)
		if type(str) == "number" then return self:removeIndex(str) end
		local f;
		for i,v in ipairs(self._.inlist) do
			if v == str then
				f = i
			end
		end
		if f then
			widget.removeListItem(self._.path, f - 1)
			table.remove(self._.inlist, f)
			return true
		end
		return false
	end
	
	function newlist:clear()
		widget.clearListItems(self._.path)
		self._.inlist = jarray()
		
	end
	
	function newlist:removeIndex(str)
		widget.removeListItem(self._.path, str - 1)
		return true
	end
	
	function newlist:relative(str)
		return self._.path.."."..str
	end
	
	function newlist:getIndex(str) -- if its a number it will get the string index if its a string it will get the key index
		if type(str) == "number" then return self._.inlist[str] end
		
		local f;
		for i,v in ipairs(self._.inlist) do
			if v == str then
				f = i
			end
		end
		
		if f then
			return f
		end
		return nil
	end
	return newlist
end

function split(inputstr, sep) --found in the web ahhaha time saving
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

function tCount(tab)
	local int = 0
	for i,v in pairs(tab) do
		int = int + 1
	end
	return int
end

function dp(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[dp(orig_key)] = dp(orig_value)
        end
        setmetatable(copy, dp(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

canvas = nil
mouse = {}

function canvasClickEvent(position, button, isButtonDown)
	if not isButtonDown then 
		mouse[button + 1] = nil
		return
	end
	mouse[button + 1] = {start = position, last = position}
	
	if button + 1 == 5 and isButtonDown then
		if editing.transform and editing.value and animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value] then
			clipboard:set(getKeyFrameTransformValue(editing.transform, editing.value))
		end
	end
	
	if button + 1 == 4 and isButtonDown then
		if editing.transform and editing.value and animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value] and clipboard:get(type(getKeyFrameTransformValue(editing.transform, editing.value)))then
			setKeyFrameTransformValue(editing.transform, editing.value, clipboard:get(type(getKeyFrameTransformValue(editing.transform, editing.value))))
		end
	end
	
	return
end

function updateMouse(canvas)
	if not canvas or not canvas.mousePosition then
		return
	end
	--world.debugText(sb.print(mouse), vec2.add(world.entityPosition(player.id()), {0,-1}), "red")
	for i,v in pairs(mouse) do
		mouse[i].last = canvas:mousePosition()
	end
end

function checkKeyFrameTransformValue(t, v)
	if not animeUI.keyFrames[animeUI.selected].transforms[t] then
		animeUI.keyFrames[animeUI.selected].transforms[t] = {}
	end
	if not animeUI.keyFrames[animeUI.selected].transforms[t][v] then
		animeUI.keyFrames[animeUI.selected].transforms[t][v] = animeUI.originalTransforms[editing.transform][editing.value]
	end
	if not animeUI.keyFrames[animeUI.selected].transforms[t]["curve"] then
		animeUI.keyFrames[animeUI.selected].transforms[t]["curve"] = 1
	end
end

function getKeyFrameTransformValue(t, v)
	checkKeyFrameTransformValue(t, v)
	return animeUI.keyFrames[animeUI.selected].transforms[t][v]
end

function setKeyFrameTransformValue(t, v, s)
	checkKeyFrameTransformValue(t, v)
	animeUI.keyFrames[animeUI.selected].transforms[t][v] = s
end

function updateCanvas(canvas)
	if not canvas then return end
	local size = canvas:size()
	canvas:clear()
	if #mouse > 0 then
		canvas:drawRect({0,0,size[1],size[2]}, {0,64,0,255})
	end
	if editing.transform and editing.value then
		if (animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value]) or editing.value == "curve" then
			local change = getKeyFrameTransformValue(editing.transform, editing.value)
			local add = nil

			if mouse[1] then
				add = vec2.mul(vec2.sub(mouse[1].last, mouse[1].lastCapture or mouse[1].last), {1/32,1/32})
				mouse[1].lastCapture = dp(mouse[1].last)
				
			elseif mouse[3] then
				add = vec2.mul(vec2.sub(mouse[3].last, mouse[3].lastCapture or mouse[3].last), {1/8,1/8})
				mouse[3].lastCapture = dp(mouse[3].last)
				
			elseif mouse[2] then
				change = animeUI.originalTransforms[editing.transform][editing.value]
				add = {0,0}
			else
				add = {0,0}
			end
			
			if type(change) == "table" then
				change = vec2.add(change, add)
			elseif type(change) == "number" then
				change = change + add[1]
			elseif editing.value == "curve" then --2018-08-03 : idk what happended here but temp bugfix
				change = 1
			end
			
			setKeyFrameTransformValue(editing.transform, editing.value, change)

			--canvas display
			local var1 = dp(getKeyFrameTransformValue(editing.transform, editing.value))
			local typevar1 = type(var1)

			if typevar1 == "number" and lastTypeEditing ~= "number" then
				lastTypeEditing = "number"
				widget.setText("clipboard_input", sb.printJson(clipboard:get("number"), 0))
			elseif typevar1 == "table" and lastTypeEditing ~= "table" then
				lastTypeEditing = "table"
				widget.setText("clipboard_input", sb.printJson(clipboard:get("table"), 0))
			end

			if typevar1 == "number" then
				while var1 > size[1] / 16 do
					var1 = var1 - (size[1] / 8)
				end
				while var1 < -(size[1] / 16) do
					var1 = var1 + (size[1] / 8)
				end
				canvas:drawLine(
					{var1 * 8 + math.floor(size[1] / 2), 0},
					{var1 * 8 + math.floor(size[1] / 2), size[2]},
					
					{255,255,255,255 - 64}, 
					1
				)
				canvas:drawText(
					sb.printJson(getKeyFrameTransformValue(editing.transform, editing.value)), {
						position = {0,0},
						horizontalAnchor = "left",
						verticalAnchor = "bottom"
					}, 
					7,
					"white"
				)
				if clipboard.number then
					canvas:drawText(
						"clipboard : "..clipboard.number, {
							position = {0,size[2] - 7},
							horizontalAnchor = "left",
							verticalAnchor = "bottom"
						}, 
						7,
						"green"
					)
				else
					canvas:drawText(
						"clipboard : none", {
							position = {0,size[2] - 7},
							horizontalAnchor = "left",
							verticalAnchor = "bottom"
						}, 
						7,
						"red"
					)
				end
			elseif typevar1 == "table" and #var1 == 2 then
				
				canvas:drawText(
					sb.printJson(getKeyFrameTransformValue(editing.transform, editing.value)), {
						position = {0,0},
						horizontalAnchor = "left",
						verticalAnchor = "bottom"
					}, 
					7,
					"white"
				)
				if clipboard.vec2 then
					canvas:drawText(
						"clipboard : "..sb.printJson(clipboard.vec2), {
							position = {0,size[2] - 7},
							horizontalAnchor = "left",
							verticalAnchor = "bottom"
						}, 
						7,
						"green"
					)
				else
					canvas:drawText(
						"clipboard : none", {
							position = {0,size[2] - 7},
							horizontalAnchor = "left",
							verticalAnchor = "bottom"
						}, 
						7,
						"red"
					)
				end
			end
			----
		end
	end
	updateMouse(canvas)
end


--callback api
function call(wid)
	if wid and _ENV["widget_"..wid] then
		_ENV["widget_"..wid]()
	end
end

function updateStatus2()
	widget.setText("status2", "Key: "..animeUI.selected.." of "..#animeUI.keyFrames)
	widget.setText("waitInput", animeUI.keyFrames[animeUI.selected].wait or 0.2)
	widget.setText("soundsInput"		, sb.printJson(animeUI.keyFrames[animeUI.selected].playSounds or jarray())		)
	widget.setText("stateInput"			, sb.printJson(animeUI.keyFrames[animeUI.selected].animationState or {})	)
	widget.setText("particleInput"		, sb.printJson(animeUI.keyFrames[animeUI.selected].burstParticle or jarray())	)
	widget.setText("lightsInput"		, sb.printJson(animeUI.keyFrames[animeUI.selected].lights or {})			)
	widget.setText("eventsInput"		, sb.printJson(animeUI.keyFrames[animeUI.selected].fireEvents or jarray())		)
end

function widget_soundsInput()
	local input = widget.getText("soundsInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" then
			animeUI.keyFrames[animeUI.selected].playSounds = e
		end
	end
end

function widget_stateInput()
	local input = widget.getText("stateInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" then
			animeUI.keyFrames[animeUI.selected].animationState = e
		end
	end
end

function widget_particleInput()
	local input = widget.getText("particleInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" then
			animeUI.keyFrames[animeUI.selected].burstParticle = e
		end
	end
end

function widget_lightsInput()
	local input = widget.getText("lightsInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" then
			animeUI.keyFrames[animeUI.selected].lights = e
		end
	end
end

function widget_eventsInput()
	local input = widget.getText("eventsInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" then
			animeUI.keyFrames[animeUI.selected].fireEvents = e
		end
	end
end

function widget_waitInput()
	animeUI.keyFrames[animeUI.selected].wait = tonumber(widget.getText("waitInput"))
end

function widget_reload()
	reloadTransforms()
end

function widget_copyy()
	animeUI.clipboard = dp(animeUI.keyFrames[animeUI.selected])
end

function widget_paste()
	if not animeUI.clipboard then return end
	table.insert(animeUI.keyFrames,animeUI.selected + 1, dp(animeUI.clipboard))
	animeUI.selected = animeUI.selected + 1
	updateStatus2()
end

function widget_next()
	animeUI.selected = math.min(animeUI.selected + 1, #animeUI.keyFrames)
	updateStatus2()
end

function widget_previous()
	animeUI.selected = math.max(animeUI.selected - 1, 1)
	updateStatus2()
end

function widget_add()
	table.insert(animeUI.keyFrames,animeUI.selected + 1, {
			transforms = {
				
			},
			wait = 0.2
		}
	)
	animeUI.selected = animeUI.selected + 1
	updateStatus2()
end

function widget_delete()
	table.remove(animeUI.keyFrames, animeUI.selected)
	if #animeUI.keyFrames == 0 then
		animeUI.keyFrames = {{
			transforms = {
				
			},
			wait = 0.2
		}}
		animeUI.selected = 1
		return
	end
	animeUI.selected = math.max(animeUI.selected - 1,1)
	updateStatus2()
end

function widget_copy()
	table.insert(animeUI.keyFrames,animeUI.selected, animeUI.keyFrames[animeUI.selected])
	animeUI.selected = #animeUI.keyFrames
	updateStatus2()
end

function widget_play()
	animeUI.playQueue = keyFramesCheck(dp(animeUI.keyFrames))
	uCooldown = 1
end

function widget_stop()
	world.sendEntityMessage(player.id(), "skipAll")
end

function removeSameOriginal(a,b) -- a to keep, b from orginal
	if b == nil then return nil end
	if type(a) == "table" then
		if (a[1] ~= b[1]) or (a[2] ~= b[2]) then
			return a
		end
		return nil
	elseif type(a) == "number" then
		if (a ~= b) then
			return a
		end
		return nil
	end
	return nil
end

function keyFramesCheck(tab)
	for n1,key in pairs(tab) do -- for each keyframes
		for tN, t in pairs(tab[n1].transforms) do -- for each transforms in a keyframe
			if animeUI.originalTransforms[tN] then
				for name, val in pairs(tab[n1].transforms[tN]) do
					if name ~= "curve" then
						tab[n1].transforms[tN][name] = removeSameOriginal(val, animeUI.originalTransforms[tN][name] or nil)
					end
				end
				if tCount(tab[n1].transforms[tN]) == 0 then
					tab[n1].transforms[tN] = nil
				end
			else
				tab[n1].transforms[tN] = nil
			end
		end
	end
	
	return tab
end

function widget_save()
	local saved = dp(animeUI.keyFrames)
	saved = keyFramesCheck(saved)
	widget.setText("animationInput", sb.printJson(saved))
end

function widget_load()
	local input = widget.getText("animationInput")
	local a, e = pcall(json.decode, input)
	if a then
		if type(e) == "table" and #e > 0 then
			animeUI.keyFrames = e
		end
		if #animeUI.keyFrames == 0 then
			widget_add()
		end
		animeUI.selected = math.max(math.min(animeUI.selected,  #animeUI.keyFrames ), 1) 
		widget.setText("animationInput", "")
	end
	updateStatus2()
end

--core
clipboard = {
	vec2 = nil,
	number = nil,
}

lastTypeEditing = ""

function clipboard:get(typ)
	if typ == "table" and self.vec2 then
		return dp(self.vec2)
	elseif typ == "number" and self.number then
		return dp(self.number)
	end
end

function clipboard:set(val)
	if not val then return end
	if type(val) == "table" and #val == 2 and type(val[1]) == "number" and type(val[2]) == "number" then
		self.vec2 = dp(val)
	elseif type(val) == "number" then
		self.number = dp(val)
	end
end

function widget_clipboard_input()
	if editing.transform and editing.value and animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value] then
		local typeVar = type(getKeyFrameTransformValue(editing.transform, editing.value))
		if typeVar == "table" then
			local a, e = pcall(json.decode, widget.getText("clipboard_input"))
			if a then
				if type(e) == "table" then
					clipboard:set(e)
				end
			end
		elseif typeVar == "number" then
			clipboard:set(tonumber( widget.getText("clipboard_input") ) or 0)
		end
		
	end
end

function dir(str, dir)
	if str:sub(1,1) == "/" then
		return str
	end
	return dir..str
end

function getWholeTransformConfig()
	local item = {}
	local handItem = world.entityHandItem(player.id(), "primary")
	if handItem then
		local itemConfig = root.itemConfig(handItem)
		local item2 = sb.jsonMerge(itemConfig.config, itemConfig.parameters)
		local animationConfig = root.assetJson(dir(item2.animation, itemConfig.directory), {})
		local animationFinal = sb.jsonMerge(animationConfig, item2.animationCustom)
		item = animationFinal
	end
	return item
end

function widget_copytransform()
	local uiConfig = root.assetJson("/animUI/clipboardui/pane.json", {})
	if animeUI.selected then
		local transforms = getWholeTransformConfig().transformationGroups or {}
		for i,v in pairs(transforms) do
			if transforms[i] then
				transforms[i].transform = sb.jsonMerge(transforms[i].transform or {}, animeUI.keyFrames[animeUI.selected].transforms[i] or {})
			end
		end
		uiConfig.clipboard = sb.printJson(transforms)
		player.interact("ScriptPane", uiConfig)
	end
end

function widget_clipboard_copy()
	if editing.transform and editing.value and animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value] then
		local var = getKeyFrameTransformValue(editing.transform, editing.value)
		clipboard:set(var)
		if type(var) == "table" then
			widget.setText("clipboard_input", sb.printJson(getKeyFrameTransformValue(editing.transform, editing.value)))
		else
			widget.setText("clipboard_input", tostring(getKeyFrameTransformValue(editing.transform, editing.value)))
		end
	end
end

function widget_clipboard_paste()
	if editing.transform and editing.value and animeUI.originalTransforms[editing.transform] and animeUI.originalTransforms[editing.transform][editing.value] and clipboard:get(type(getKeyFrameTransformValue(editing.transform, editing.value)))then
		setKeyFrameTransformValue(editing.transform, editing.value, clipboard:get(type(getKeyFrameTransformValue(editing.transform, editing.value))))
	end
end

animeUI = {
	playQueue = nil,
	rpc = {},
	clipboard = nil,
	originalTransforms = {},
	selected = 1,
	keyFrames = {
		{
			transforms = {
				
			},
			wait = 0.2
		}
	},
}
tSelect = ""
transformslist = nil
vSelect = ""
valueslist = nil
editing = {transform = nil, value = nil}
setT = "a"
uCooldown = 0

function init()
	transformslist = bindList("transforms.list")
	valueslist = bindList("values.list")
	canvas = widget.bindCanvas("canvas")
	updateStatus2()
end

function uninit()
	world.sendEntityMessage(player.id(), "enableAim")
end

function update(dt)
	updateCanvas(canvas)
	for i,v in pairs(animeUI.rpc) do
		if v.pending:finished() and v.pending:result() ~= nil then
			v.callback(v.pending:result())
			animeUI.rpc[i] = nil
		elseif v.pending:finished() and v.pending:result() == nil then
			animeUI.rpc[i] = nil
		end
	end
	local newselect = transformslist:selected()
	if newselect and newselect ~= tSelect then
		loadValues(animeUI.originalTransforms[widget.getData(transformslist:relative(newselect)).name])
		tSelect = newselect
	end
	local newselect2 = valueslist:selected()
	if newselect2 and newselect2 ~= vSelect then
		editing.transform = widget.getData(transformslist:relative(newselect)).name
		editing.value = widget.getData(valueslist:relative(newselect2)).name
		vSelect = newselect2
	end
	if not animeUI.rpc[setT] and not animeUI.playQueue then
		local var1 = world.sendEntityMessage(player.id(), "isAnyPlaying")
		if type(var1) == "userdata" then
			setT = rpcCallback(var1, function(res)
				if res then return end
				world.sendEntityMessage(player.id(), "setTransforms", tempCurve(animeUI.keyFrames[animeUI.selected].transforms) or {})
			end)
		elseif var1 == false then
			world.sendEntityMessage(player.id(), "setTransforms", tempCurve(animeUI.keyFrames[animeUI.selected].transforms) or {})
		end
	elseif animeUI.playQueue then
		world.sendEntityMessage(player.id(), "play", animeUI.playQueue)
		animeUI.playQueue = nil
	end
	uCooldown = math.max(uCooldown - dt, 0)
	world.sendEntityMessage(player.id(), "disableAim")
end

function tempCurve(tr)
	local ntr = dp(tr)
	for i,v in pairs(tr) do
		ntr[i].curve = 0
	end
	return ntr
end

function rpcCallback(r, func)
	local i = sb.makeUuid()
	animeUI.rpc[i] = {pending = r, callback = func}
	return i
end

function sortKeys(tab)
	local tab1 = {}
	for i,v in pairs(tab) do
		table.insert(tab1, i)
	end
	table.sort(tab1, function( a,b ) return a < b end)
	local tab2 = {}
	for i,v in ipairs(tab1) do
		tab2[v] = tab[v]
	end
	return tab2
end

function loadTransforms(tab)
	animeUI.originalTransforms = sortKeys(tab)
	
	transformslist:clear()
	
	for i,v in pairs(animeUI.originalTransforms) do
		if not v.ignore then
			local ntr = transformslist:add()
			widget.setText(transformslist:relative(ntr)..".name", i)
			widget.setData(transformslist:relative(ntr), {name = i})
		end
	end
	
	transformslist:select(transformslist:getIndex(1))
end

function loadValues(tab1)
	tab1 = sortKeys(tab1)
	valueslist:clear()
	tab1.curve = 1
	for i,v in pairs(tab1) do
		local ntr = valueslist:add()
		widget.setText(valueslist:relative(ntr)..".name", i)
		widget.setData(valueslist:relative(ntr), {name = i})
	end
	if tCount(tab1) == 0 then return end
	valueslist:select(valueslist:getIndex(1))
end

function reloadTransforms()
	rpcCallback(world.sendEntityMessage(player.id(), "getTransforms"), loadTransforms)
end

--