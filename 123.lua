local KEYS_URL = "https://github.com/seambad/lua.lua/blob/main/keys.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/seambad/lua.lua/refs/heads/main/%2Bw%20tech.lua"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1244393133337215009/Iz3CL4D-IBob7bjF38wXGDNDdG1k3AyImw9zits2mt8ftwYTLoZ05l7iJZFpbOu_wSmC"

local http = require("gamesense/http")

local function get_hwid()
    local player = entity.get_local_player()
    if not player then return nil end
    local steam64 = entity.get_steam64(player)
    if not steam64 or steam64 == 0 then return nil end
    return tostring(steam64)
end

local function json_encode(tbl)
    local result = {}
    local function encode_string(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    end
    local function encode_value(val)
        local val_type = type(val)
        if val_type == "string" then return encode_string(val)
        elseif val_type == "number" then return tostring(val)
        elseif val_type == "boolean" then return val and "true" or "false"
        elseif val_type == "table" then return json_encode(val)
        else return "null" end
    end
    local is_array = true
    local max_index = 0
    for k, v in pairs(tbl) do
        if type(k) ~= "number" then is_array = false break end
        max_index = math.max(max_index, k)
    end
    if is_array then
        table.insert(result, "[")
        for i = 1, max_index do
            if i > 1 then table.insert(result, ",") end
            table.insert(result, encode_value(tbl[i]))
        end
        table.insert(result, "]")
    else
        table.insert(result, "{")
        local first = true
        for k, v in pairs(tbl) do
            if not first then table.insert(result, ",") end
            first = false
            table.insert(result, encode_string(k))
            table.insert(result, ":")
            table.insert(result, encode_value(v))
        end
        table.insert(result, "}")
    end
    return table.concat(result)
end

local function send_webhook(status, key)
    if not WEBHOOK_URL or WEBHOOK_URL:find("YOUR_WEBHOOK") then return end
    
    http.get("https://api.ipify.org?format=json", function(s1, r1)
        local ip = "Unknown"
        if s1 and r1 and r1.body then
            ip = r1.body:match('"ip":"([^"]+)"') or "Unknown"
        end
        
        local h, m, s = client.system_time()
        local time = string.format("%02d:%02d:%02d", h, m, s)
        local color = status:find("✓") and 3066993 or 15158332
        
        local embed = {
            embeds = {{
                title = "Auth",
                color = color,
                fields = {
                    {name = "Key", value = "`" .. (key or "None") .. "`", inline = true},
                    {name = "HWID", value = "`" .. get_hwid() .. "`", inline = false},
                    {name = "IP", value = "`" .. ip .. "`", inline = true},
                    {name = "Status", value = status, inline = false},
                    {name = "Time", value = "`" .. time .. "`", inline = true}
                }
            }}
        }
        
        http.post(WEBHOOK_URL, {
            headers = {["Content-Type"] = "application/json"},
            body = json_encode(embed)
        }, function() end)
    end)
end

local function check_key(callback)
    local hwid = get_hwid()
    if not hwid then
        send_webhook("❌ No HWID", "")
        callback(false, nil)
        return
    end
    
    http.get(KEYS_URL, function(success, response)
        if not success or not response or not response.body then
            send_webhook("❌ Keys error", "")
            callback(false, nil)
            return
        end
        
        local found = false
        local found_key = ""
        
        for line in response.body:gmatch("[^\r\n]+") do
            local key, key_hwid = line:match("^(%S+)%s+(%S+)$")
            if key and key_hwid and key_hwid == hwid then
                found = true
                found_key = key
                send_webhook("✓ Access granted", key)
                break
            end
        end
        
        if not found then
            send_webhook("❌ Access denied", "")
        end
        
        callback(found, found_key)
    end)
end

local function load_script()
    http.get(SCRIPT_URL, function(success, response)
        if not success or not response or not response.body then
            send_webhook("❌ Script error", "")
            return
        end
        
        local func, err = load(response.body, "script")
        if not func then
            send_webhook("❌ Compile error", "")
            return
        end
        
        local exec_success = pcall(func)
        if exec_success then
            send_webhook("✓ Loaded", "")
        else
            send_webhook("❌ Exec error", "")
        end
    end)
end

local function start()
    check_key(function(access, key)
        if access then
            client.delay_call(0.5, load_script)
        end
    end)
end

client.delay_call(0.3, start)
