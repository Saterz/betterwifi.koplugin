local NetworkMgr = require("ui/network/manager")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local Network = {}

-- local function is_open_network()
--     local flags = network.flags or ""
--     local upper = flags:upper()
    
--     local encrypted = upper:find("WPA")
-- end

function Network:password_prompt(ssid, on_submit)
    local password_dialog = InputDialog:new{
        title = "Wi-Fi Password",
        description = ("Network: %s"):format(ssid),
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

function Network:connect_to_wifi(ssid, password)
    local network = {
        ssid = ssid,
        password = password
    }
    
    local ok, message = NetworkMgr:authenticateNetwork(network)
    
    if not ok then
        UIManager:show(InfoMessage:new{ text = ("Wi-Fi auth failed: %s"):format(message or "unknown error") })
        return
    end
    
    NetworkMgr:obtainIP()
    
    UIManager:show(InfoMessage:new{ text = ("Connected to %s"):format(ssid) })
end

return Network