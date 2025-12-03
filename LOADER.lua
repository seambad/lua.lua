-- HrisitoSense Loader с проверкой HWID, времени и отправкой в Discord
-- Автор: 180z
-- Версия: 2.0 - Только в игре

-- ============================================
-- КОНФИГУРАЦИЯ
-- ============================================

-- Вставьте данные из генератора ключей
local FIVE_DIGIT_KEY = "58463"  -- 5-значный ключ
local ENCODED_KEY = "M0RXR1Q6MTg5OTI5NjE3MzoxNzo0MzoxNg=="  -- Base64 ключ (KEY:HWID:TIME)
local DAYS_LIMIT = 30  -- Лимит дней (7, 14, 30, 90 или nil для безлимита)

-- URL где лежит ваш Lua скрипт (Pastebin Raw, GitHub Raw, или ваш сервер)
local SCRIPT_URL = "https://raw.githubusercontent.com/seambad/lua.lua/refs/heads/main/%2Bw%20tech.lua"

-- Discord Webhook URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/1244393133337215009/Iz3CL4D-IBob7bjF38wXGDNDdG1k3AyImw9zits2mt8ftwYTLoZ05l7iJZFpbOu_wSmC"

-- ============================================
-- DECODER BASE64
-- ============================================
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64_decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b64chars:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function base64_encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b64chars:sub(c+1,c+1)
    end)..({'','==','='})[#data%3+1])
end

local function hash_to_5digit(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 99999
    end
    return string.format("%05d", hash)
end

-- ============================================
-- HWID (ТОЛЬКО В ИГРЕ)
-- ============================================
local function get_current_hwid()
    local local_player = entity.get_local_player()
    if not local_player then 
        return nil, "Вы не в игре"
    end
    
    local steam64 = entity.get_steam64(local_player)
    if not steam64 or steam64 == 0 then 
        return nil, "Steam64 недоступен"
    end
    
    return tostring(steam64), nil
end

local function is_in_game()
    return entity.get_local_player() ~= nil
end

-- ============================================
-- ПАРСИНГ КЛЮЧА
-- ============================================
local function parse_key(encoded_key)
    if not encoded_key or encoded_key == "" then return nil end
    
    local decoded = base64_decode(encoded_key)
    local parts = {}
    for part in decoded:gmatch("[^:]+") do
        table.insert(parts, part)
    end
    if #parts < 5 then return nil end
    return {
        original_key = parts[1],
        hwid = parts[2],
        time = parts[3] .. ":" .. parts[4] .. ":" .. parts[5]
    }
end

-- ============================================
-- ПРОВЕРКА ВРЕМЕНИ
-- ============================================
local function days_passed_since_key()
    local db_key = "key_activation_" .. FIVE_DIGIT_KEY
    local activation_unix = database.read(db_key)
    if not activation_unix then
        activation_unix = client.unix_time()
        database.write(db_key, activation_unix)
    end
    local current_unix = client.unix_time()
    local diff_seconds = current_unix - activation_unix
    return math.floor(diff_seconds / 86400)
end

-- ============================================
-- JSON ENCODER
-- ============================================
local function json_encode(tbl)
    local result = {}
    
    local function encode_string(str)
        return '"' .. tostring(str):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    end
    
    local function encode_value(val)
        local val_type = type(val)
        if val_type == "string" then
            return encode_string(val)
        elseif val_type == "number" then
            return tostring(val)
        elseif val_type == "boolean" then
            return val and "true" or "false"
        elseif val_type == "table" then
            return json_encode(val)
        else
            return "null"
        end
    end
    
    local is_array = true
    local max_index = 0
    for k, v in pairs(tbl) do
        if type(k) ~= "number" then
            is_array = false
            break
        end
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

-- ============================================
-- HTTP
-- ============================================
local http = require("gamesense/http") or http

local function get_ip_address(callback)
    http.get("https://api.ipify.org?format=json", function(success, response)
        if success and response and response.body then
            local ip = response.body:match('"ip":"([^"]+)"')
            callback(ip or "Unknown")
        else
            callback("Unknown")
        end
    end)
end

local function send_to_webhook(info)
    if not WEBHOOK_URL or WEBHOOK_URL:find("YOUR_WEBHOOK") then
        return
    end
    
    local h, m, s = client.system_time()
    local current_time = string.format("%02d:%02d:%02d", h, m, s)
    
    local days_used = days_passed_since_key()
    local days_left = DAYS_LIMIT and (DAYS_LIMIT - days_used) or "∞"
    
    local embed = {
        embeds = {{
            title = "🔓 Скрипт загружен",
            color = 3066993,
            fields = {
                {name = "📋 Ключ", value = "`" .. info.key .. "`", inline = true},
                {name = "🔑 5-значный", value = "`" .. FIVE_DIGIT_KEY .. "`", inline = true},
                {name = "🆔 HWID", value = "`" .. info.hwid .. "`", inline = false},
                {name = "🌐 IP адрес", value = "`" .. info.ip .. "`", inline = true},
                {name = "🕐 Время загрузки", value = "`" .. current_time .. "`", inline = true},
                {name = "📅 Осталось дней", value = "`" .. tostring(days_left) .. "`", inline = true},
                {name = "⏱️ Использовано дней", value = "`" .. days_used .. "`", inline = true}
            },
            footer = {text = "HrisitoSense Loader • " .. current_time}
        }}
    }
    
    local json_data = json_encode(embed)
    
    http.post(WEBHOOK_URL, {
        headers = {["Content-Type"] = "application/json"},
        body = json_data
    }, function(success, response)
        if not success then
            log("⚠ Не удалось отправить webhook", {r=255, g=165, b=0})
        end
    end)
end

-- ============================================
-- ЛОГИРОВАНИЕ
-- ============================================
local function log(msg, color)
    if color then
        client.color_log(color.r, color.g, color.b, "[Loader] " .. msg)
    else
        client.log("[Loader] " .. msg)
    end
end

-- ============================================
-- ЗАГРУЗКА СКРИПТА
-- ============================================
local function download_and_load_script(callback)
    log("Загрузка скрипта", {r=255, g=255, b=0})
    
    http.get(SCRIPT_URL, function(success, response)
        if not success then
            log("❌ Ошибка загрузки с сервера!", {r=255, g=0, b=0})
            if callback then callback(false) end
            return
        end
        
        if not response or not response.body then
            log("❌ Пустой ответ от сервера!", {r=255, g=0, b=0})
            if callback then callback(false) end
            return
        end
        
        local script_code = response.body
        log("Получено " .. #script_code .. " байт", {r=0, g=255, b=255})
        
        local script_func, err = load(script_code, "remote_script")
        if not script_func then
            log("❌ Ошибка компиляции: " .. tostring(err), {r=255, g=0, b=0})
            if callback then callback(false) end
            return
        end
        
        local exec_success, exec_err = pcall(script_func)
        if not exec_success then
            log("❌ Ошибка выполнения: " .. tostring(exec_err), {r=255, g=0, b=0})
            if callback then callback(false) end
            return
        end
        
        log("✓ Скрипт успешно загружен!", {r=0, g=255, b=0})
        if callback then callback(true) end
    end)
end

-- ============================================
-- ГЛАВНАЯ ПРОВЕРКА
-- ============================================
local script_loaded = false
local status_label

local function unload_script()
    if not script_loaded then
        log("Скрипт не загружен!", {r=255, g=165, b=0})
        return
    end
    
    log("Выгрузка скрипта...", {r=255, g=255, b=0})
    client.reload_active_scripts()
    script_loaded = false
    ui.set(status_label, "Скрипт выгружен")
    log("✓ Скрипт выгружен!", {r=0, g=255, b=0})
end

local function verify_and_load()
    log("═════════════════════", {r=255, g=255, b=0})
    log("Проверка ключа...", {r=255, g=255, b=0})
    log("═════════════════════", {r=255, g=255, b=0})
    
    -- КРИТИЧЕСКИ ВАЖНО: Проверяем что мы в игре
    if not is_in_game() then
        log("❌ Вы должны быть в игре!", {r=255, g=0, b=0})
        log("Зайдите на сервер или запустите карту", {r=255, g=165, b=0})
        ui.set(status_label, "✗ Зайдите в игру!")
        return false
    end
    
    local key_data = parse_key(ENCODED_KEY)
    if not key_data then
        log("❌ Неверный формат ключа!", {r=255, g=0, b=0})
        ui.set(status_label, "✗ Неверный формат ключа")
        return false
    end
    
    log("Ключ: " .. key_data.original_key, {r=0, g=255, b=255})
    log("Время: " .. key_data.time, {r=0, g=255, b=255})
    
    -- Проверка 5-значного ключа
    local calculated_hash = hash_to_5digit(ENCODED_KEY)
    if calculated_hash ~= FIVE_DIGIT_KEY then
        log("❌ 5-значный ключ не совпадает!", {r=255, g=0, b=0})
        log("Ожидается: " .. calculated_hash, {r=255, g=100, b=0})
        ui.set(status_label, "✗ Неверный ключ")
        return false
    end
    log("✓ 5-значный ключ верный!", {r=0, g=255, b=0})
    
    -- Проверка HWID
    local current_hwid, err = get_current_hwid()
    if not current_hwid then
        log("❌ Не удалось получить HWID: " .. err, {r=255, g=0, b=0})
        ui.set(status_label, "✗ " .. err)
        return false
    end
    
    if key_data.hwid ~= current_hwid then
        log("❌ HWID не совпадает!", {r=255, g=0, b=0})
        log("Ожидается: " .. key_data.hwid, {r=255, g=100, b=0})
        log("Ваш HWID: " .. current_hwid, {r=255, g=100, b=0})
        ui.set(status_label, "✗ HWID не совпадает")
        return false
    end
    log("✓ HWID совпадает!", {r=0, g=255, b=0})
    
    -- Проверка времени
    if DAYS_LIMIT then
        local days = days_passed_since_key()
        if days > DAYS_LIMIT then
            log("❌ Ключ истек! " .. days .. "/" .. DAYS_LIMIT .. " дней", {r=255, g=0, b=0})
            ui.set(status_label, "✗ Ключ истек")
            return false
        end
        log("✓ Осталось: " .. (DAYS_LIMIT - days) .. "/" .. DAYS_LIMIT .. " дней", {r=0, g=255, b=0})
    else
        log("✓ Безлимитный ключ", {r=0, g=255, b=0})
    end
    
    -- Загрузка
    log("Загрузка скрипта...", {r=255, g=255, b=0})
    ui.set(status_label, "⟳ Загрузка")
    
    get_ip_address(function(ip)
        local webhook_info = {
            key = key_data.original_key,
            hwid = current_hwid,
            ip = ip
        }
        
        send_to_webhook(webhook_info)
        
        download_and_load_script(function(success)
            if success then
                script_loaded = true
                ui.set(status_label, "✓ Скрипт активен!")
                log("═════════════════════", {r=0, g=255, b=0})
            else
                ui.set(status_label, "✗ Ошибка загрузки")
            end
        end)
    end)
    
    return true
end

-- ============================================
-- UI
-- ============================================
ui.new_label("LUA", "A", "═══ HrisitoSense Loader ═══")

-- Показываем статус игры
local game_status = ui.new_label("LUA", "A", "Статус: Проверка...")

local key_info = parse_key(ENCODED_KEY)
if key_info then
    ui.new_label("LUA", "A", "Ключ: " .. key_info.original_key)
    ui.new_label("LUA", "A", "5-значный: " .. FIVE_DIGIT_KEY)
    ui.new_label("LUA", "A", "Время: " .. key_info.time)
    if DAYS_LIMIT then
        ui.new_label("LUA", "A", "Лимит: " .. DAYS_LIMIT .. " дней")
    else
        ui.new_label("LUA", "A", "Лимит: безлимит")
    end
end

status_label = ui.new_label("LUA", "A", "Нажмите 'Войти'")

ui.new_button("LUA", "A", "Войти", function()
    verify_and_load()
end)

ui.new_button("LUA", "A", "Выгрузить скрипт", function()
    unload_script()
end)

ui.new_button("LUA", "A", "Мой HWID", function()
    local hwid, err = get_current_hwid()
    if hwid then
        log("Ваш HWID: " .. hwid, {r=0, g=255, b=0})
        log("Steam64: " .. hwid, {r=0, g=255, b=255})
    else
        log("❌ " .. err, {r=255, g=0, b=0})
        log("Зайдите в игру для получения HWID", {r=255, g=165, b=0})
    end
end)

ui.new_button("LUA", "A", "Проверить статус", function()
    if is_in_game() then
        local hwid = get_current_hwid()
        log("✓ Вы в игре", {r=0, g=255, b=0})
        log("HWID доступен: " .. hwid, {r=0, g=255, b=255})
        ui.set(game_status, "Статус: В игре ✓")
    else
        log("✗ Вы в главном меню", {r=255, g=165, b=0})
        log("Зайдите на сервер или запустите карту", {r=255, g=165, b=0})
        ui.set(game_status, "Статус: В меню ✗")
    end
end)

-- Paint индикатор
client.set_event_callback("paint", function()
    if not script_loaded then return end
    local sw, sh = client.screen_size()
    renderer.text(sw/2, 10, 0, 255, 0, 255, "c", 0, " ")
end)

-- Проверка статуса каждые 2 секунды
local last_check = 0
client.set_event_callback("paint", function()
    local current_time = globals.realtime()
    if current_time - last_check > 2 then
        last_check = current_time
        if is_in_game() then
            ui.set(game_status, "Статус: В игре ✓")
        else
            ui.set(game_status, "Статус: В меню (требуется игра)")
        end
    end
end)

log("Лоадер инициализирован", {r=0, g=255, b=255})
log("ВАЖНО: Для загрузки скрипта зайдите в игру!", {r=255, g=165, b=0})
