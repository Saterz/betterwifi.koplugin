local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local NetworkMgr = require("ui/network/manager")
local Network = require("network")
local _ = require("gettext")

local function nearby_networks()
	return NetworkMgr:getNetworkList() or {}
end

local BetterWifi = WidgetContainer:extend{
    name = "betterwifi",
    is_doc_only = false,
}

function BetterWifi:init()
    self.ui.menu:registerToMainMenu(self)
end

local function network_details_dialog(network)
    if not network then
        UIManager:show(InfoMessage:new{
            text = _("No network data")
        })
        return
    end
    
    local ssid = network.ssid or _("Hidden SSID")
    
    local lines = {"SSID: " .. ssid}
    if network.signal_level ~= nil then
        table.insert(lines, "Signal level: " .. tostring(network.signal_level))
    end
    
    UIManager:show(InfoMessage:new{
        text = table.concat(lines, "\n")
    })
end

local function manage_network_submenu(network)
    local submenu = {
        {
            text = network.ssid or _("Hidden SSID"),
            enabled = false
        },
        {
            text = _("Connect"),
            callback = function()
                if network.password and #network.password > 0 then
                    Network:connect_to_wifi(
                        network.ssid,
                        network.password
                       )
                else
                    Network:password_prompt(
                        network.ssid,
                        function(password)
                            Network:connect_to_wifi(network.ssid, password)
                        end
                    )
                end
            end,
        },
        {
            text = _("Forget"),
            callback = function()
                -- TODO: implement forgetting network functionality
            end
        },
        {
            text = _("Info"),
            callback = function()
                network_details_dialog(network)
            end
        }
    }
    
    return submenu
end

local function nearby_list_submenu()
	local networks = nearby_networks()

	local items = {}
	for _, network in ipairs(networks) do
		table.insert(items, {
			text = network.ssid or _("Hidden SSID"),
            sub_item_table = manage_network_submenu(network),
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
