local logger = require("logger")

local ffi = require("ffi")
local C = ffi.C

local Kindle = {}

local function kindleGetSavedNetworks()
    local haslipc, lipc = pcall(require, "libopenlipclua") -- use our lua lipc library with access to hasharray properties
    local lipc_handle
    if haslipc then
        lipc_handle = lipc.open_no_name()
    end
    if lipc_handle then
        local ha_input = lipc_handle:new_hasharray() -- an empty hash array since we only want to read
        local success, ha_result = pcall(function()
            return lipc_handle:access_hash_property("com.lab126.wifid", "profileData", ha_input)
        end)
        if success then
            local profiles = ha_result:to_table()
            ha_result:destroy()
            ha_input:destroy()
            lipc_handle:close()
            return profiles
        else
            logger.warn("kindleGetSavedNetworks: failed to access profileData")
            ha_input:destroy()
            lipc_handle:close()
            return {}
        end
    end
end

local function kindleGetCurrentProfile()
    local haslipc, lipc = pcall(require, "libopenlipclua") -- use our lua lipc library with access to hasharray properties
    local lipc_handle
    if haslipc then
        lipc_handle = lipc.open_no_name()
    end
    if lipc_handle then
        local ha_input = lipc_handle:new_hasharray() -- an empty hash array since we only want to read
        local success, ha_result = pcall(function()
            return lipc_handle:access_hash_property("com.lab126.wifid", "currentEssid", ha_input)
        end)

        if success then
            local profile = ha_result:to_table()[1] -- there is only a single element
            ha_input:destroy()
            ha_result:destroy()
            lipc_handle:close()
            return profile
        else
            logger.warn("kindleGetCurrentProfile: failed to access currentEssid")
            ha_input:destroy()
            lipc_handle:close()
            return nil
        end
    else
        return nil
    end
end

local function kindleGetScanList()
    local _ = require("gettext")
    local haslipc, lipc = pcall(require, "libopenlipclua") -- use our lua lipc library with access to hasharray properties
    local lipc_handle
    if haslipc then
        lipc_handle = lipc.open_no_name()
    end
    if lipc_handle then
            local ha_input = lipc_handle:new_hasharray()
            local success_scan, ha_results = pcall(function()
                return lipc_handle:access_hash_property("com.lab126.wifid", "scanList", ha_input)
            end)
            if not success_scan then
                logger.warn("kindleGetScanList: failed to access scanList")
                ha_input:destroy()
                lipc_handle:close()
                return {}, nil
            end
            if ha_results == nil then
                -- Shouldn't really happen, access_hash_property will throw if LipcAccessHasharrayProperty failed
                ha_input:destroy()
                lipc_handle:close()
                -- NetworkMgr will ask for a re-scan on seeing an empty table, the second attempt *should* work ;).
                return {}, nil
            end
            local scan_result = ha_results:to_table()
            ha_results:destroy()
            ha_input:destroy()
            lipc_handle:close()
            if not scan_result then
                -- e.g., to_table hit lha->ha == NULL
                return {}, nil
            else
                return scan_result, nil
            end
    else
        logger.dbg("kindleGetScanList: Failed to acquire an anonymous lipc handle")
        return nil, _("Unable to communicate with the Wi-Fi backend")
    end
end

local function kindleScanThenGetResults()
    local _ = require("gettext")
    local haslipc, lipc = pcall(require, "liblipclua")
    local lipc_handle
    if haslipc then
        lipc_handle = lipc.init("com.github.koreader.networkmgr")
    end
    if not lipc_handle then
        logger.dbg("kindleScanThenGetResults: Failed to acquire a lipc handle for NetworkMgr")
        return nil, _("Unable to communicate with the Wi-Fi backend")
    end

    lipc_handle:set_string_property("com.lab126.wifid", "scan", "") -- trigger a scan

    -- Mimic WpaClient:scanThenGetResults: block while waiting for the scan to finish.
    -- Ideally, we'd do this via a poll/event workflow, but, eh', this is going to be good enough for now ;p.
    -- For future reference, see `lipc-wait-event -m -s 0 -t com.lab126.wifid '*'`
    --[[
        -- For a connection:
        [00:00:04.675699] cmStateChange "PENDING"
        [00:00:04.677402] scanning
        [00:00:05.488043] scanComplete
        [00:00:05.973188] cmConnected
        [00:00:05.977862] cmStateChange "CONNECTED"
        [00:00:05.980698] signalStrength "1/5"
        [00:00:06.417549] cmConnected

        -- And a disconnection:
        [00:01:34.094652] cmDisconnected
        [00:01:34.096088] cmStateChange "NA"
        [00:01:34.219802] signalStrength "0/5"
        [00:01:34.221802] cmStateChange "READY"
        [00:01:35.656375] cmIntfNotAvailable
        [00:01:35.658710] cmStateChange "NA"
    --]]
    local done_scanning = false
    local wait_cnt = 80 -- 20s in chunks on 250ms
    while wait_cnt > 0 do
        local success, scan_state = pcall(function()
            return lipc_handle:get_string_property("com.lab126.wifid", "scanState")
        end)

        if not success then
            logger.warn("kindleScanThenGetResults: failed to get scanState, aborting scan")
            break
        end

        if scan_state == "idle" then
            done_scanning = true
            logger.dbg("kindleScanThenGetResults: Wi-Fi scan took", (80 - wait_cnt) * 0.25, "seconds")
            break
        end

        -- Whether it's still "scanning" or in whatever other state we don't know about,
        -- try again until it says it's done.
        wait_cnt = wait_cnt - 1
        C.usleep(250 * 1000)
    end
    lipc_handle:close()

    if done_scanning then
        return kindleGetScanList()
    else
        logger.warn("kindleScanThenGetResults: Timed-out scanning for Wi-Fi networks")
        return nil, _("Scanning for Wi-Fi networks timed out")
    end
end

function Kindle:getNetworkList()
        local scan_list, err = kindleScanThenGetResults()
        if not scan_list then
            return nil, err
        end

         -- trick ui/widget/networksetting into displaying the correct signal strength icon
        local qualities = {
            [1] = 0,
            [2] = 6,
            [3] = 31,
            [4] = 56,
            [5] = 81
        }

        local network_list = {}
        local saved_profiles = kindleGetSavedNetworks()
        local current_profile = kindleGetCurrentProfile()
        for _, network in ipairs(scan_list) do
            local password = nil
            if network.known == "yes" then
                for _, p in ipairs(saved_profiles) do
                    -- Earlier FW do not have a netid field at all, fall back to essid as that's the best we'll get (we don't get bssid either)...
                    if (p.netid and p.netid == network.netid) or (p.netid == nil and p.essid == network.essid) then
                        password = p.psk
                        break
                    end
                end
            end
            table.insert(network_list, {
                -- signal_level is purely for fun, the widget doesn't do anything with it. The WpaClient backend stores the raw dBa attenuation in it.
                signal_level = string.format("%d/%d", network.signal, network.signal_max),
                signal_quality = qualities[network.signal],
                -- See comment above about netid being unfortunately optional...
                connected = (current_profile.netid and current_profile.netid ~= -1 and current_profile.netid == network.netid)
                         or (current_profile.netid == nil and current_profile.essid ~= "" and current_profile.essid == network.essid),
                flags = network.key_mgmt,
                ssid = network.essid ~= "" and network.essid,
                password = password,
            })
        end
        return network_list, nil
    end

return Kindle