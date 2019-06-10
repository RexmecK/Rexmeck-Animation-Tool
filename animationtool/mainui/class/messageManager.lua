module = {
    rpcs = {}
}

function module:init()
    widgetBind("reload", 
        function() 
            self:refreshTransforms()
        end
    )
    widgetBind("play", 
        function() 
            world.sendEntityMessage(player.loungingIn() or player.id(), "play", key:validate())
        end
    )
end

function module:update()
    self:updateEditTransforms()
    self:updateRPC()
end

function module:uninit()
    world.sendEntityMessage(player.loungingIn() or player.id(), "enableAim")
end

local function tablesortkey(tbl)
	local tosort = {}
	
	for i,v in pairs(tbl) do
		table.insert(tosort, {key = i, value = v})
	end
	
	table.sort(tosort, 
		function(a,b)
			return a.key < b.key
		end
	)
	
	return tosort
end

--user function
function module:refreshTransforms(id) --id is optionnal
    if not id then id = player.loungingIn() or player.id() end
    if not world.entityExists(id) then
        return false
    end
    self:addRPC(world.sendEntityMessage(id, "getTransforms"), 
        function(data)
            if not data then return end
            for i,v in pairs(data) do
                if not data[i].curve then
                    data[i].curve = 1
                end
            end
            
            local sorteddata = tablesortkey(data)

            selector.transforms:clear()
            selector.values:clear()
            for i,v in ipairs(sorteddata) do
                selector.transforms:add(v.key)
            end
            key.transformsDefault = copycat(data)
            key.transformsHasRefreshed = true
        end
    )
    return true
end

--RPC STUFF
setT = ""
function module:updateEditTransforms()
    if player.isLounging() or world.entityHandItem(player.id(), "primary") or world.entityHandItem(player.id(), "alt") then
        if not self.rpcs[setT] then
        setT = self:addRPC(world.sendEntityMessage(player.loungingIn() or player.id(), "isAnyPlaying"), 
                function(data)
                    if type(data) == "boolean" and not data then
                        local toset = copycat(key:key())
                        for i,v in pairs(toset.transforms) do toset.transforms[i].curve = 0 end
                        world.sendEntityMessage(player.loungingIn() or player.id(), "disableAim")
                        world.sendEntityMessage(player.loungingIn() or player.id(), "setTransforms", toset.transforms)
                    end
                end
           )
        end
    end
end

function module:updateRPC()
    for i,v in pairs(self.rpcs) do
        if self.rpcs[i].rpc:finished() then
            self.rpcs[i].func(self.rpcs[i].rpc:result())
            self.rpcs[i] = nil
        end
    end
end

function module:addRPC(r,func)
    if type(r) ~= "userdata" then func(r) return end
    local id = sb.makeUuid()
    self.rpcs[id] = {rpc = r, func = func}
    return id
end

