--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local BetterWifi = WidgetContainer:extend{
    name = "betterwifi",
    is_doc_only = false,
}

function BetterWifi:init()
    self.ui.menu:registerToMainMenu(self)
end

function BetterWifi:addToMainMenu(menu_items)
    menu_items.betterwifi = {
        text = _("Better WiFi"),
        -- in which menu this should be appended
        sorting_hint = "setting",

	sub_item_table = {
	  {
	    text = _("Activate"),
	    callback = function()
	      UIManager:show(
		InfoMessage:new{text=_("Test")}
	      )
	    end,
	  }
	},

        -- a callback when tapping
        callback = function()
            UIManager:show(InfoMessage:new{
                text = _("Hello, plugin world"),
            })
        end,
    }
end

return BetterWifi
