local NetworkMgr = require("ui/network/manager")
local BtrNetworkMgr = require("network_mgr")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

-- Adaptation of KoReader's native NetworkItem object for BetterWifi
local NetworkItem = {}

function NetworkItem:new(info)
    local obj = {
        info = info
    }
    setmetatable(obj, self)
    self.__index = self
    return obj:init()
end

function NetworkItem:init()
    if not self.info.ssid then self.info.ssid = _("Hidden SSID") end
    self.text = self.info.ssid
    self.sub_item_table_func = function()
        return self:manage_network_submenu()
    end
    return self
end

function NetworkItem:manage_network_submenu()
    local network = self.info
    
    local submenu = {
        {
            text = network.ssid,
            enabled = false
        },
        {
            text = _("Connect"),
            enabled_func = function()
                return not network.connected
            end,
            callback = function()
                if network.password and #network.password > 0 then
                    self:connect()
                else
                    self:password_prompt(function(password)
                        network.password = password
                        self:connect()
                    end)
                end
            end,
        },
        {
            text = _("Disconnect"),
            enabled_func = function()
                return network.connected
            end,
            callback = function()
                self:disconnect()
            end
        },
        {
            text = _("Forget"),
            callback = function()
                self:forget()
            end
        },
        {
            text = _("Info"),
            callback = function()
                self:details_dialog()
            end
        }
    }
    
    return submenu
end

function NetworkItem:details_dialog()
    local network = self.info
    local lines = {
        "SSID: " .. network.ssid,
        "Signal level: " .. tostring(network.signal_level),
        "Signal quality: " .. tostring(network.signal_quality) .. "%",
        "Flags: " .. tostring(network.flags),
    }
    
    UIManager:show(InfoMessage:new{
        text = table.concat(lines, "\n")
    })
end

function NetworkItem:password_prompt(on_submit)
    local network = self.info
    
    local password_dialog = InputDialog:new {
        title = _("Wi-Fi Password"),
        description = (_("Network: %s")):format(network.ssid),
        input = "",
        text_type = "password",
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(password_dialog)
                    end,
                },
                {
                    text = _("Connect"),
                    is_enter_default = true,
                    callback = function()
                        local password = password_dialog:getInputText()
                        UIManager:close(password_dialog)
                        on_submit(password)
                    end,
                },
            }
        }
    }

    UIManager:show(password_dialog)
    password_dialog:onShowKeyboard()
end

function NetworkItem:connect()
    local network = self.info
    local current_network = BtrNetworkMgr:getConnectedNetwork()
    if current_network then
        current_network:disconnect()
    end

    local success, err_msg = NetworkMgr:authenticateNetwork(network)

    local text
    if success then
        NetworkMgr:obtainIP()
        text = _("Connected.")
        network.connected = true
        BtrNetworkMgr:setConnectedNetwork(self)
    else
        text = err_msg or _("Connection failed.")
    end

    UIManager:show(InfoMessage:new { text = text, timeout = 3 })
end

function NetworkItem:disconnect()
    local info = InfoMessage:new{text = _("Disconnecting…")}
    UIManager:show(info)
    UIManager:forceRePaint()

    NetworkMgr:disconnectNetwork(self.info)
    NetworkMgr:releaseIP()

    UIManager:close(info)
    self.info.connected = false
    BtrNetworkMgr:setConnectedNetwork(nil)
end

function NetworkItem:forget()
    NetworkMgr:deleteNetwork(self.info)
    self.info.password = nil
end

return NetworkItem
