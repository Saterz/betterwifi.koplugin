local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local NetworkMgr = require("ui/network/manager")
local NetworkItem = require("network_item")
local BtrNetworkMgr = require("network_mgr")
local _ = require("gettext")

local BetterWifi = WidgetContainer:extend{
    name = "betterwifi",
    is_doc_only = false,
}

function BetterWifi:init()
    self.ui.menu:registerToMainMenu(self)
end

local function nearby_list_submenu()
	local networks = BtrNetworkMgr:getNearbyNetworkList()

	local items = {}
	for i, network in ipairs(networks) do
		table.insert(items, NetworkItem:new(network))
	end

	return items
end

function BetterWifi:addToMainMenu(menu_items)
    menu_items.betterwifi = {
        text = _("Better WiFi"),
        sorting_hint = "setting",
        sub_item_table = {
          {
            text = _("Activate"),
            checked_func = function()
              return NetworkMgr:isWifiOn()
            end,
            callback = function()
              if NetworkMgr:isWifiOn() then
                  NetworkMgr:disableWifi()
              else
                  NetworkMgr:enableWifi()
              end
            end,
          },
          {
            text = _("Nearby networks"),
            sub_item_table_func = function()
            	 return nearby_list_submenu()
            end,
            enabled_func = function()
                return NetworkMgr:isWifiOn()
            end
          }
        },
    }
end

return BetterWifi
