local KindleNet = require("device/kindle")
local NetworkMgr = require("ui/network/manager")
local Device = require("device")

local BtrNetworkMgr = {
    current_network = nil
}

function BtrNetworkMgr:getNearbyNetworkList()
    if Device:isKindle() then
        return KindleNet:getNetworkList() or {}
    else
        return NetworkMgr:getNetworkList() or {}
    end
end

function BtrNetworkMgr:setConnectedNetwork(network)
    self.current_network = network
end

function BtrNetworkMgr:getConnectedNetwork()
    return self.current_network
end

return BtrNetworkMgr
