local ConfigMap = {
    [121864768012064] = {
        url = "https://pastefy.app/Lz141pDR/raw"
    },
    [93978595733734] = {
        url = "https://raw.githubusercontent.com/zerotheking152-png/QuantumCOM/refs/heads/main/QHComunnity.lua"
    },
    [126884695634066] = {
        url = "https://raw.githubusercontent.com/zerotheking152-png/QuantumGAG/main/QHCommunity.lua"
    },
    [83369512629707] = {
        url = "https://raw.githubusercontent.com/zerotheking152-png/QuantumSAWAH/refs/heads/main/Community.lua"
    }
}

local config = ConfigMap[game.PlaceId]

if config and config.url then
    print("Loading script for PlaceId:", game.PlaceId)

    local success, response = pcall(function()
        return game:HttpGet(config.url)
    end)

    if success and response then
        local ok, err = pcall(function()
            loadstring(response)()
        end)

        if not ok then
            warn("Execute error:", err)
        end
    else
        warn("Fetch error:", response)
    end
else
    warn("Map tidak support:", game.PlaceId)
end
