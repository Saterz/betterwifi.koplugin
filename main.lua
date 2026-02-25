--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local NetworkMgr = require("ui/network/manager")
local _ = require("gettext")

local networks = {}

local BetterWifi = WidgetContainer:extend{
    name = "betterwifi",
    is_doc_only = false,
}

function BetterWifi:init()
    self.ui.menu:registerToMainMenu(self)
end

local function refresh_nearby_networks()
	networks = NetworkMgr:getNetworkList() or {}
end

local function nearby_list_submenu()
	refresh_nearby_networks()

	local items = {}
	for _, network in ipairs(networks) do
		table.insert(items, {
			text = _(network.ssid) or _("Hidden SSID")
		})
	end

	return items
end

function BetterWifi:addToMainMenu(menu_items)
    menu_items.betterwifi = {
        text = _("Better WiFi"),
        -- in which menu this should be appended
        sorting_hint = "setting",

	sub_item_table = {
		{
			text = _("Activate"),
			checked_func = function()
				return NetworkMgr:isWifiOn()
			end,
			callback = function()
				NetworkMgr:enableWifi(function()
					networks = NetworkMgr:getNetworkList()
				end, true)
			end,
		},
		{
			text = _("Nearby networks"),
			sub_item_table = nearby_list_submenu()
		}
	},
}
end

return BetterWifi
