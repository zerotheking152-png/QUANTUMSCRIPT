local ConfigMap = {

    -- Fish it
    [121864768012064] = {
        url = "link script"
    },

    -- Violence Distrik
    [93978595733734] = {
        url = "https://raw.githubusercontent.com/zerotheking152-png/QuantumCOM/refs/heads/main/QHComunnity.lua"
    },

    -- Grow a garden
    [126884695634066] = {
        url = "https://raw.githubusercontent.com/zerotheking152-png/QuantumGAG/main/QHCommunity.lua"
    }
}

local config = ConfigMap[game.PlaceId]

if config then
    print("Loading:", game.PlaceId)
    pcall(function()
        loadstring(game:HttpGet(config.url))()
    end)
else
    warn("Map tidak support:", game.PlaceId)
end
