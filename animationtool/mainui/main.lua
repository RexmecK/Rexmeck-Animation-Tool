_LOCALPATH = "/animationtool/mainui/"
function lp(var)
	if not var then return end
	if string.sub(var, 1,1) == "/" then
		return var 
	else 
		return _LOCALPATH..var
	end 
end

require(lp("util.lua"))
require(lp("moduleloader.lua"))

modules = {

}

profiling = {

}

config = {}
function init()
    config = root.assetJson(lp("config.json"), {})

    for i,v in pairs(config.scripts or {}) do
        _ENV[i] = loadModule(lp(v))
        modules[i] = {}
        --profiling[i] = 0
        pathNames[lp(v)] = i
    end

    for i,v in pairs(modules) do
        if _ENV[i].init then
            --local clk = os.clock()
            _ENV[i]:init()
            --profiling[i] = lerp(profiling[i], os.clock() - clk, 2)
        end
    end
end

function update()
    for i,v in pairs(modules) do
        if _ENV[i].update then
            --local clk = os.clock()
            _ENV[i]:update()
            --profiling[i] = lerp(profiling[i], os.clock() - clk, 2)
        end
    end
end

function uninit()
    for i,v in pairs(modules) do
        if _ENV[i].uninit then
            --local clk = os.clock()
            _ENV[i]:uninit()
            --profiling[i] = lerp(profiling[i], os.clock() - clk, 2)
        end
    end
    --sb.logInfo("AVG clocks: "..sb.printJson(profiling, 1))
end

--class pathing
function pathName(v)
    return pathNames[lp(v)]
end

pathNames = {}

--callbacks
function handleMouse(...)
    _mouseHandler(...)
end

_mouseHandler = function() end

function bindMouseHandler(func)
    _mouseHandler = func or function() end
end

widgetBinding = {

}

function widgetBind(wid, func)
    if type(func) ~= "function" then return false end
    widgetBinding[wid] = func
    return true
end

function call(wid)
    if widgetBinding[wid] then
        widgetBinding[wid]()
    end
end
