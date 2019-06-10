module = {
    currentedit = "",
    selected = {
        transforms = false,
        values = false
    },
    transforms = false,
    values = false,
}

function module:newlist(path)
    widget.clearListItems(path)
    local n = {
        path = path,
        _list = {},
        empty = true
    }

    function n:clear()
        self._list = {}
        self.empty = true
        widget.clearListItems(self.path)
    end

    function n:getSelected()
        local sel = widget.getListSelected(self.path)
        if not sel then return false end
        return self._list[sel]
    end

    function n:index(name)
        for i,v in pairs(self._list) do
            if v == name then return i end
        end
    end

    function n:add(name)
        local id = widget.addListItem(self.path)
        widget.setText(self.path.."."..id..".name", name)
        self._list[id] = name
        self.empty = false
        return id
    end

    return n
end

function module:init()
    self.transforms = self:newlist("transforms.list")
    self.values = self:newlist("values.list")
end

function module:update()
    self:updateSelected()
end

function module:uninit()
    
end

function module:updateSelected()
    if not self.transforms.empty then
        local selectedtransforms = self.transforms:getSelected()
        local selectedvalues = self.values:getSelected()
        if self.selected.transforms ~= selectedtransforms or self.selected.values ~= selectedvalues then
        
            if self.selected.transforms ~= selectedtransforms and key.transformsDefault[selectedtransforms] then
                self.values:clear()
                for i,v in pairs(key.transformsDefault[selectedtransforms]) do
                    self.values:add(i)
                end
            end
        
            self.selected.transforms = selectedtransforms
            self.selected.values = false
            editor:setEditing(selectedtransforms, selectedvalues)
        end
    end
end