clipboard = "a"
function init()
    clipboard = config.getParameter("clipboard", clipboard)
    widget.setText("clipout",clipboard)
    widget.focus("clipout")
end

function call(wid)
    if _ENV["widget_"..wid] then
        _ENV["widget_"..wid]()
    end
end

function widget_clipout()
    if widget.getText("clipout") ~= clipboard then
        pane.dismiss()
    end
end