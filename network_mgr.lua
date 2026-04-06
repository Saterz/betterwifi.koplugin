local KindleNetworkBackend = require("device/kindle")
local NetworkMgr = require("ui/network/manager")
local Device = require("device")

local BetterWifiNetworkManager = {
    current_network = nil
}

function BetterWifiNetworkManager:getNearbyNetworkList()
    if Device:isKindle() then
        return KindleNetworkBackend:getNetworkList() or {}
    else
        return NetworkMgr:getNetworkList() or {}
    end
end

function BetterWifiNetworkManager:setConnectedNetwork(network)
    self.current_network = network
end

function BetterWifiNetworkManager:getConnectedNetwork()
    return self.current_network
end

return BetterWifiNetworkManager
