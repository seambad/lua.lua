-- ʙʏ ʟ41337 && 2ʙ3ꜰ
local vector = require 'vector'
local c_entity = require 'gamesense/entity'
local http = require 'gamesense/http'
local base64 = require 'gamesense/base64'
local clipboard = require 'gamesense/clipboard'
local steamworks = require 'gamesense/steamworks'

-- =========== НАЧАЛО КОДА ЭКРАНА ЗАГРУЗКИ ===========
local obex_data = obex_fetch and obex_fetch() or {username = 'User', build = 'BETA', discord=''}

local function lerp(a, b, t)
    return a + (b - a) * t
end

local visual_functions = {}

local intro = {}

-- Таблица этапов загрузки с модулями
local loading_stages = {
    {progress = 0, text = "Initializing core..."},
    {progress = 0.1, text = "Loading visual modules..."},
    {progress = 0.25, text = "Setting up UI framework..."},
    {progress = 0.4, text = "Configuring anti-aim..."},
    {progress = 0.55, text = "Loading weapon configurations..."},
    {progress = 0.7, text = "Setting up rage bot..."},
    {progress = 0.85, text = "Finalizing settings..."},
    {progress = 1.0, text = "Ready!"}
}

-- Функция для получения имени пользователя с Pastebin
function visual_functions:fetch_username_from_pastebin()
    if not http then
        print("[W.tech] HTTP module not available, using default username")
        return false
    end
    
    -- Замените YOUR_PASTEBIN_ID на ID вашего Pastebin
    -- Пример: если ссылка https://pastebin.com/raw/abc123, то ID = "abc123"
    local pastebin_url = "https://pastebin.com/raw/YOUR_PASTEBIN_ID"
    
    http.get(pastebin_url, function(success, response)
        if success and response.status == 200 then
            local username = response.body:gsub("%s+", "")  -- Убираем пробелы и переносы строк
            if username and #username > 0 then
                obex_data.username = username
                print("[W.tech] Username loaded from Pastebin: " .. username)
                
                -- Обновляем полный текст приветствия в интро
                if intro[1] then
                    intro[1].full_message = "+W.tech recode loading Welcome back " .. obex_data.username .. '.'
                end
            else
                print("[W.tech] Empty username from Pastebin, using default")
                -- Используем имя по умолчанию
                if intro[1] then
                    intro[1].full_message = "+W.tech recode loading Welcome back " .. obex_data.username .. '.'
                end
            end
        else
            print("[W.tech] Failed to fetch username from Pastebin, using default")
            -- Используем имя по умолчанию
            if intro[1] then
                intro[1].full_message = "+W.tech recode loading Welcome back " .. obex_data.username .. '.'
            end
        end
    end)
end

function visual_functions:welcome_to_starlight()
   local w,h = client.screen_size()
   
    -- Создаем полное сообщение с именем по умолчанию
    local full_message = "+W.tech recode loading Welcome back " .. obex_data.username .. '.'
    
    intro[#intro + 1] ={
        full_message = full_message,  -- Полное сообщение с именем
        main_alpha = 0,  -- Альфа для основного сообщения
        success_alpha = 0,  -- Альфа для сообщения об успешной загрузке
        timer = 1800,  -- УВЕЛИЧЕНО общее время (с 1200 до 1800)
        initial_timer = 1800,
        fade_in_time = 150,    -- Время появления
        fill_time = 600,       -- Время заполнения круга
        transition_time = 200, -- Время перехода от основного к успешному сообщению
        success_hold_time = 550, -- УВЕЛИЧЕНО время показа успешного сообщения (с 150 до 550)
        fade_out_time = 300,   -- Время исчезновения
        progress_complete = false,
        y_offset = 50,  -- Начальное смещение по Y для анимации появления
        scale = 0.8,    -- Начальный масштаб для анимации
        x = w / 2 - 150,
        y = h / 2,
        bg_alpha = 0, -- Альфа для фона (добавлено для отдельного управления)
        show_success_message = false, -- Флаг для отображения сообщения об успешной загрузке
        main_y_offset = 0, -- Отдельное смещение для основного сообщения
        success_y_offset = 30, -- Начальное смещение для сообщения об успешной загрузке
        current_stage_index = 1, -- Текущий этап загрузки
        stage_alpha = 0, -- Альфа для текста этапа загрузки
        stage_timer = 0, -- Таймер для смены этапов
        checkmark_animation = 0, -- Прогресс анимации галочки (0-1)
        checkmark_pulse = 0, -- Пульсация галочки
    }
    
    -- Пытаемся получить имя с Pastebin после создания интро
    if http then
        visual_functions:fetch_username_from_pastebin()
    end
end

visual_functions.welcome_to_starlight()

function visual_functions:get_current_stage(progress)
    for i = #loading_stages, 1, -1 do
        if progress >= loading_stages[i].progress then
            return loading_stages[i]
        end
    end
    return loading_stages[1]
end

function visual_functions:start_intro()
    local w,h = client.screen_size()
    for i = 1,#intro do
        if intro[i] == nil then break end

        -- Рассчитываем прошедшее время
        local time_passed = intro[i].initial_timer - intro[i].timer
        
        -- ФАЗА 1: Появление (fade-in)
        if time_passed < intro[i].fade_in_time then
            local fade_in_progress = time_passed / intro[i].fade_in_time
            intro[i].main_alpha = lerp(0, 255, fade_in_progress)
            intro[i].bg_alpha = lerp(0, 200, fade_in_progress)
            intro[i].main_y_offset = lerp(50, 0, fade_in_progress)
            intro[i].scale = lerp(0.8, 1.0, fade_in_progress)
            intro[i].progress = 0
            intro[i].progress_complete = false
            intro[i].show_success_message = false
            intro[i].success_alpha = 0
            intro[i].success_y_offset = 30
            intro[i].stage_alpha = lerp(0, 255, fade_in_progress)
            intro[i].current_stage_index = 1
            intro[i].stage_timer = 0
            intro[i].checkmark_animation = 0
            intro[i].checkmark_pulse = 0
        
        -- ФАЗА 2: Загрузка (fill)
        elseif time_passed < intro[i].fade_in_time + intro[i].fill_time then
            local fill_progress = (time_passed - intro[i].fade_in_time) / intro[i].fill_time
            intro[i].main_alpha = 255
            intro[i].bg_alpha = 200
            intro[i].main_y_offset = 0
            intro[i].scale = 1.0
            intro[i].progress = fill_progress
            intro[i].progress_complete = false
            intro[i].show_success_message = false
            intro[i].success_alpha = 0
            intro[i].success_y_offset = 30
            intro[i].stage_alpha = 255
            
            -- Обновляем текущий этап загрузки
            local current_stage = visual_functions:get_current_stage(fill_progress)
            
            -- Находим индекс текущего этапа
            for idx, stage in ipairs(loading_stages) do
                if stage == current_stage then
                    intro[i].current_stage_index = idx
                    break
                end
            end
            
            -- Увеличиваем таймер для анимации текста
            intro[i].stage_timer = intro[i].stage_timer + 1
            
            -- Показываем сообщение об успешной загрузке когда прогресс 100%
            if fill_progress >= 1.0 then
                intro[i].show_success_message = true
                intro[i].success_alpha = 0
            end
        
        -- ФАЗА 3: Переход от основного к успешному сообщению
        elseif time_passed < intro[i].fade_in_time + intro[i].fill_time + intro[i].transition_time then
            local transition_progress = (time_passed - (intro[i].fade_in_time + intro[i].fill_time)) / intro[i].transition_time
            
            -- Исчезает основное сообщение, появляется сообщение об успешной загрузке
            intro[i].main_alpha = lerp(255, 0, transition_progress)
            intro[i].success_alpha = lerp(0, 255, transition_progress)
            intro[i].stage_alpha = lerp(255, 0, transition_progress)
            
            -- Анимация галочки появляется с небольшим запаздыванием
            intro[i].checkmark_animation = lerp(0, 1, math.max(0, (transition_progress - 0.3) / 0.7))
            
            intro[i].bg_alpha = 200
            intro[i].main_y_offset = lerp(0, -30, transition_progress)  -- Основное уезжает вверх
            intro[i].success_y_offset = lerp(30, 0, transition_progress)  -- Успешное приезжает на место
            intro[i].scale = 1.0
            intro[i].progress = 1.0
            intro[i].progress_complete = true
            intro[i].show_success_message = true
        
        -- ФАЗА 4: Удержание успешного сообщения (УВЕЛИЧЕНО ВРЕМЯ) - С ПУЛЬСАЦИЕЙ ГАЛОЧКИ
        elseif time_passed < intro[i].fade_in_time + intro[i].fill_time + intro[i].transition_time + intro[i].success_hold_time then
            local hold_progress = (time_passed - (intro[i].fade_in_time + intro[i].fill_time + intro[i].transition_time)) / intro[i].success_hold_time
            
            intro[i].main_alpha = 0
            intro[i].success_alpha = 255  -- Постоянная видимость успешного сообщения
            intro[i].bg_alpha = 200
            intro[i].main_y_offset = -30
            intro[i].success_y_offset = 0  -- Успешное сообщение на месте
            intro[i].scale = 1.0
            intro[i].progress = 1.0
            intro[i].progress_complete = true
            intro[i].show_success_message = true
            intro[i].stage_alpha = 0
            intro[i].checkmark_animation = 1
            
            -- Пульсация галочки (0-1)
            intro[i].checkmark_pulse = 0.5 + 0.5 * math.sin(globals.realtime() * 3)
        
        -- ФАЗА 5: Плавное исчезновение успешного сообщения
        else
            local time_in_fade_out = time_passed - (intro[i].fade_in_time + intro[i].fill_time + intro[i].transition_time + intro[i].success_hold_time)
            local fade_out_progress = time_in_fade_out / intro[i].fade_out_time
            
            -- Убедимся, что fade_out_progress не превышает 1
            fade_out_progress = math.min(fade_out_progress, 1.0)
            
            intro[i].main_alpha = 0  -- Основное уже исчезло
            intro[i].success_alpha = lerp(255, 0, fade_out_progress)
            intro[i].bg_alpha = lerp(200, 0, fade_out_progress)
            intro[i].main_y_offset = -30
            intro[i].success_y_offset = lerp(0, -30, fade_out_progress)  -- Успешное уезжает вверх
            intro[i].scale = lerp(1.0, 0.9, fade_out_progress)
            intro[i].progress = 1.0
            intro[i].progress_complete = true
            intro[i].show_success_message = true
            intro[i].stage_alpha = 0
            intro[i].checkmark_animation = lerp(1, 0, fade_out_progress)
            intro[i].checkmark_pulse = 0
        end

        -- Фон с увеличенным затемнением при запуске
        renderer.rectangle(0, 0, w, h, 0, 0, 0, intro[i].bg_alpha)
        
        -- ============================================
        -- ОСНОВНОЕ СООБЩЕНИЕ (исчезает в фазе 3)
        -- ============================================
        if intro[i].main_alpha > 0 then
            -- Рассчитываем позицию с учетом анимации
            local current_y = h / 2 + intro[i].main_y_offset
            
            -- СИМБОЛ (◣ _ ◢) НА 15 ПИКСЕЛЕЙ ВЫШЕ (РАСПОЛОЖЕН ЧУТЬ НИЖЕ, ЧЕМ БЫЛО)
            local symbol_y = current_y - 15  -- Изменено с 25 на 15
            
            -- Рисуем символ с плавным появлением и красным цветом (УМЕНЬШЕННЫЙ ФЛАГ "c" вместо "c+")
            renderer.text(w / 2, symbol_y, 
                         255, 0, 0, intro[i].main_alpha, "c", 0,  -- Изменено с "c+" на "c"
                         "(◣ _ ◢)")
            
            -- Тень символа для объемности (УМЕНЬШЕННЫЙ ФЛАГ "c" вместо "c+")
            renderer.text(w / 2 + 2, symbol_y + 2, 
                         0, 0, 0, intro[i].main_alpha * 0.3, "c", 0,  -- Изменено с "c+" на "c"
                         "(◣ _ ◢)")
            
            -- Основной текст с анимацией
            local full_message = intro[i].full_message or "+W.tech recode loading Welcome back " .. obex_data.username .. '.'
            
            -- Разделяем текст на "+W.tech" и остальную часть
            local prefix = "+W.tech"
            local suffix = full_message:sub(#prefix + 1)
            
            -- Измеряем ширину префикса
            local prefix_width = renderer.measure_text(nil, prefix)
            
            -- Рассчитываем начальную позицию для центрирования всей строки
            local total_width = renderer.measure_text(nil, full_message)
            local start_x = w / 2 - total_width / 2
            
            -- Рисуем "+W.tech" красным цветом
            renderer.text(start_x, current_y, 
                         255, 0, 0, intro[i].main_alpha, nil, 0,
                         prefix)
            
            -- Рисуем остальной текст белым цветом
            renderer.text(start_x + prefix_width, current_y, 
                         255, 255, 255, intro[i].main_alpha, nil, 0,
                         suffix)
            
            -- Текст сборки
            local build_text = "build "
            local beta_text = string.upper(obex_data.build)
            
            -- Измеряем ширину текста "build "
            local build_width = renderer.measure_text(nil, build_text)
            local beta_width = renderer.measure_text(nil, beta_text)
            
            -- Рассчитываем начальную позицию для центрирования всей строки
            local total_build_width = build_width + beta_width
            local build_start_x = w / 2 - total_build_width / 2
            
            -- Рисуем "build " белым цветом
            renderer.text(build_start_x, current_y + 25, 
                         255, 255, 255, intro[i].main_alpha, nil, 0, 
                         build_text)
            
            -- Рисуем "BETA" красным цветом
            renderer.text(build_start_x + build_width, current_y + 25, 
                         255, 0, 0, intro[i].main_alpha, nil, 0,
                         beta_text)

            -- Радиус круга
            local radius = 10 * intro[i].scale
            
            -- Позиция круга с учетом анимации
            local circle_y = current_y + 50
            
            -- Рисуем фон круга (полный круг) с плавным появлением
            renderer.circle_outline(w / 2, circle_y, 
                                   40, 40, 40, intro[i].main_alpha, 
                                   radius, 0, 1, 2 * intro[i].scale)
            
            -- Рисуем заполняющуюся часть (процент заполнения) с плавным появлением
            if intro[i].progress > 0 then
                renderer.circle_outline(w / 2, circle_y, 
                                       255, 0, 0, intro[i].main_alpha,
                                       radius, 0, intro[i].progress, 2 * intro[i].scale)
            end
            
            -- Отображаем проценты под кругом
            local percent = math.floor(intro[i].progress * 100)
            renderer.text(w / 2, circle_y + radius + 15, 
                         255, 255, 255, intro[i].main_alpha, "c", 0, 
                         percent .. "%")
            
            -- ============================================
            -- ТЕКСТ ТЕКУЩЕГО ЭТАПА ЗАГРУЗКИ ПОД ПРОГРЕСС-БАРОМ
            -- ============================================
            if intro[i].stage_alpha > 0 then
                local stage_text_y = circle_y + radius + 40
                
                -- Получаем текущий этап загрузки
                local current_stage = visual_functions:get_current_stage(intro[i].progress)
                
                if current_stage then
                    -- Декоративные точки перед текстом (анимированные)
                    local dots = ""
                    local dot_count = math.floor((intro[i].stage_timer % 30) / 10)
                    
                    for j = 1, 3 do
                        if j <= dot_count then
                            dots = dots .. "."
                        else
                            dots = dots .. " "
                        end
                    end
                    
                    -- Текст этапа загрузки
                    local stage_text = current_stage.text
                    local full_stage_text = dots .. " " .. stage_text
                    local stage_width = renderer.measure_text(nil, full_stage_text)
                    local stage_x = w / 2 - stage_width / 2
                    
                    -- Рисуем текст этапа загрузки
                    renderer.text(stage_x, stage_text_y, 
                                 200, 200, 200, intro[i].stage_alpha, nil, 0,
                                 full_stage_text)
                    
                    -- Декоративная линия над текстом этапа
                    local line_width = 150
                    local line_x = w / 2 - line_width / 2
                    renderer.rectangle(line_x, stage_text_y - 5, line_width, 1, 
                                     100, 100, 100, intro[i].stage_alpha * 0.3)
                end
            end
        end
        
        -- ============================================
        -- СООБЩЕНИЕ ОБ УСПЕШНОЙ ЗАГРУЗКЕ: СИМВОЛ (◣ _ ◢) НАД ТЕКСТОМ "+W.tech recode loaded"
        -- ============================================
        if intro[i].show_success_message and intro[i].success_alpha > 0 then
            -- Позиционируем сообщение по центру экрана с учетом анимации
            local message_y = h / 2 + intro[i].success_y_offset
            
            -- 1. СИМБОЛ (◣ _ ◢) НАД ТЕКСТОМ (+20 пикселей выше) (УМЕНЬШЕННЫЙ РАЗМЕР)
            local symbol_text = "(◣ _ ◢)"
            
            -- Рисуем символ красным цветом с центрированием (УМЕНЬШЕННЫЙ ФЛАГ "c" вместо "c+")
            renderer.text(w / 2, message_y - 20, 
                         255, 0, 0, intro[i].success_alpha, "c", 0,  -- Изменено с "c+" на "c"
                         symbol_text)
            
            -- 2. ОСНОВНАЯ НАДПИСЬ: "+W.tech recode loaded" ПОД СИМВОЛОМ
            -- Разделяем на части для разного цвета
            local prefix = "+W.tech"
            local recode_text = " recode "
            local loaded_text = " loaded "
            
            -- Измеряем ширину каждой части
            local prefix_width = renderer.measure_text(nil, prefix)
            local recode_width = renderer.measure_text(nil, recode_text)
            local loaded_width = renderer.measure_text(nil, loaded_text)
            
            -- Рассчитываем общую ширину и начальную позицию (без галочки)
            local total_width = prefix_width + recode_width + loaded_width
            local start_x = w / 2 - total_width / 2
            
            -- Рисуем "+W.tech" красным цветом
            renderer.text(start_x, message_y, 
                         255, 0, 0, intro[i].success_alpha, nil, 0,
                         prefix)
            
            -- Рисуем " recode " БЕЛЫМ цветом
            renderer.text(start_x + prefix_width, message_y, 
                         255, 255, 255, intro[i].success_alpha, nil, 0,
                         recode_text)
            
            -- Рисуем " loaded " белым цветом
            renderer.text(start_x + prefix_width + recode_width, message_y, 
                         255, 255, 255, intro[i].success_alpha, nil, 0,
                         loaded_text)
            
            -- 3. КРАСИВАЯ АНИМИРОВАННАЯ ГАЛОЧКА
            local checkmark_x = start_x + total_width + 5
            local checkmark_y = message_y
            
            -- Базовый размер галочки
            local base_size = 12
            
            -- Анимация масштаба галочки
            local checkmark_scale = intro[i].checkmark_animation * (1 + 0.1 * intro[i].checkmark_pulse)
            
            -- Цвет галочки с пульсацией
            local green_intensity = 150 + 105 * intro[i].checkmark_pulse
            local checkmark_alpha = intro[i].success_alpha * intro[i].checkmark_animation
            
            -- Рисуем свечение/тень галочки (3 слоя для объемности)
            for offset = 1, 3 do
                local glow_alpha = checkmark_alpha * (0.3 - 0.1 * offset)
                renderer.text(checkmark_x + offset, checkmark_y + offset, 
                             0, green_intensity, 0, glow_alpha, nil, 0,
                             "✓")
            end
            
            -- Основная галочка с анимацией
            renderer.text(checkmark_x, checkmark_y, 
                         0, green_intensity, 0, checkmark_alpha, nil, 0,
                         "✓")
            
            -- Блестящий эффект на галочке (маленькая точка)
            if intro[i].checkmark_animation > 0.5 then
                local sparkle_alpha = checkmark_alpha * intro[i].checkmark_pulse
                renderer.text(checkmark_x + 3, checkmark_y - 3, 
                             255, 255, 255, sparkle_alpha, nil, 0,
                             ".")
            end
            
            -- 4. ПОЛОСКА-РАЗДЕЛИТЕЛЬ (ТАКАЯ ЖЕ, КАК В 1 ЭТАПЕ)
            local line_width = 150
            local line_x = w / 2 - line_width / 2
            local line_y = message_y + 20  -- 5 пикселей выше текста "Good Luck !"
            
            -- Рисуем декоративную линию
            renderer.rectangle(line_x, line_y, line_width, 1, 
                             100, 100, 100, intro[i].success_alpha * 0.3)
            
            -- 5. ТЕКСТ "Good Luck !" СНИЗУ (ЧУТЬ НИЖЕ ПОЛОСКИ)
            local good_luck_text = "Good Luck !"
            local good_luck_width = renderer.measure_text(nil, good_luck_text)
            local good_luck_x = w / 2 - good_luck_width / 2
            
            -- Рисуем текст "Good Luck !" белым цветом
            renderer.text(good_luck_x, message_y + 25, 
                         255, 255, 255, intro[i].success_alpha * 0.8, nil, 0,
                         good_luck_text)
        end
        -- ============================================

        intro[i].timer = intro[i].timer - 1 

        -- Удаляем интро, когда альфа становится 0
        if intro[i].main_alpha <= 0 and intro[i].success_alpha <= 0 and intro[i].timer < intro[i].initial_timer - intro[i].fade_out_time then
            table.remove(intro,#intro)
        end
    end
end

-- Обработчик экрана загрузки
client.set_event_callback("paint", function()
    visual_functions.start_intro()
end)

-- Вызываем загрузку имени при запуске скрипта
client.delay_call(0, function()
    if http then
        visual_functions:fetch_username_from_pastebin()
    end
end)
-- =========== КОНЕЦ КОДА ЭКРАНА ЗАГРУЗКИ ===========

local client_set_event_callback, client_unset_event_callback = client.set_event_callback, client.unset_event_callback
local entity_get_local_player, entity_get_player_weapon, entity_get_prop = entity.get_local_player, entity.get_player_weapon, entity.get_prop
local ui_get, ui_set, ui_set_callback, ui_set_visible, ui_reference, ui_new_checkbox, ui_new_slider = ui.get, ui.set, ui.set_callback, ui.set_visible, ui.reference, ui.new_checkbox, ui.new_slider

local reference = {
    double_tap = {ui.reference('RAGE', 'Aimbot', 'Double tap')},
    duck_peek_assist = ui.reference('RAGE', 'Other', 'Duck peek assist'),
	pitch = {ui.reference('AA', 'Anti-aimbot angles', 'Pitch')},
    yaw_base = ui.reference('AA', 'Anti-aimbot angles', 'Yaw base'),
    yaw = {ui.reference('AA', 'Anti-aimbot angles', 'Yaw')},
    yaw_jitter = {ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')},
    body_yaw = {ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')},
    freestanding_body_yaw = ui.reference('AA', 'anti-aimbot angles', 'Freestanding body yaw'),
	edge_yaw = ui.reference('AA', 'Anti-aimbot angles', 'Edge yaw'),
	freestanding = {ui.reference('AA', 'Anti-aimbot angles', 'Freestanding')},
    roll = ui.reference('AA', 'Anti-aimbot angles', 'Roll'),
    on_shot_anti_aim = {ui.reference('AA', 'Other', 'On shot anti-aim')},
    slow_motion = {ui.reference('AA', 'Other', 'Slow motion')}
}

local globals_frametime = globals.frametime
local globals_tickinterval = globals.tickinterval
local entity_is_enemy = entity.is_enemy
local entity_is_dormant = entity.is_dormant
local entity_is_alive = entity.is_alive
local entity_get_origin = entity.get_origin
local entity_get_player_resource = entity.get_player_resource
local table_insert = table.insert
local math_floor = math.floor

local last_press = 0
local direction = 0
local anti_aim_on_use_direction = 0
local cheked_ticks = 0

local E_POSE_PARAMETERS = {
    STRAFE_YAW = 0,
    STAND = 1,
    LEAN_YAW = 2,
    SPEED = 3,
    LADDER_YAW = 4,
    LADDER_SPEED = 5,
    JUMP_FALL = 6,
    MOVE_YAW = 7,
    MOVE_BLEND_CROUCH = 8,
    MOVE_BLEND_WALK = 9,
    MOVE_BLEND_RUN = 10,
    BODY_YAW = 11,
    BODY_PITCH = 12,
    AIM_BLEND_STAND_IDLE = 13,
    AIM_BLEND_STAND_WALK = 14,
    AIM_BLEND_STAND_RUN = 14,
    AIM_BLEND_CROUCH_IDLE = 16,
    AIM_BLEND_CROUCH_WALK = 17,
    DEATH_YAW = 18
}

local function contains(source, target)
	for id, name in pairs(ui.get(source)) do
		if name == target then
			return true
		end
	end

	return false
end

local function is_defensive(index)
    cheked_ticks = math.max(entity.get_prop(index, 'm_nTickBase'), cheked_ticks or 0)

    return math.abs(entity.get_prop(index, 'm_nTickBase') - cheked_ticks) > 2 and math.abs(entity.get_prop(index, 'm_nTickBase') - cheked_ticks) < 14
end

local settings = {}
local anti_aim_settings = {}
local anti_aim_states = {'Global', 'Standing', 'Moving', 'Slow motion', 'Crouching', 'Crouching & moving', 'In air', 'In air & crouching', 'No exploits', 'On use'}
local anti_aim_different = {'', ' ', '  ', '   ', '    ', '     ', '      ', '       ', '        ', '         '}

current_tab = ui.new_combobox('AA', 'Anti-aimbot angles', 'Tabs', {'Home', 'Anti-Aim', 'Misc', 'Visuals'})

local text1 = ui.new_label('AA', 'Anti-aimbot angles', '+W.tech ~ \a95b806ffDEBUG', 'string')
local text2 = ui.new_label('AA', 'Anti-aimbot angles', 'CODERS L4 & 2b3f ', 'string')
local text3 = ui.new_label('AA', 'Anti-aimbot angles', 'if you find a bug, write to discord ticket', 'string')
settings.anti_aim_state = ui.new_combobox('AA', 'Anti-aimbot angles', 'Anti-aimbot state', anti_aim_states)

local master_switch = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Log Aimbot Shots')
local console_filter = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Console Filter')
local anim_breakerx = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Animation Breaker')
local force_safe_point = ui.reference('RAGE', 'Aimbot', 'Force safe point')
local rage_anti_aim_correction = ui.reference('RAGE', 'Other', 'Anti-aim correction')
local _orig_anti_aim_correction = nil
local trashtalk = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Trash Talk')
local clantagchanger = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Clan Tag')
local fastladder = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Fast Ladder')
local hitmarker = ui.new_checkbox('AA', 'Anti-aimbot angles', '3D Hit Marker')
-- Misc: +w confidence resolver (AI math layer + velocity + ML persistence)
local confidence_checkbox = ui.new_checkbox('AA', 'Anti-aimbot angles', '+ᴡ ᴄᴏɴꜰɪᴅᴇɴᴄᴇ')
local confidence_indicator = ui.new_checkbox('AA', 'Anti-aimbot angles', '+ᴡ ᴄᴏɴꜰɪᴅᴇɴᴄᴇ overlay')
local confidence_strength = ui.new_slider('AA', 'Anti-aimbot angles', 'Confidence strength', 0, 100, 50, true, '%')
local confidence_apply_to_aa = ui.new_checkbox('AA', 'Anti-aimbot angles', '+ᴡ ᴄᴏɴꜰɪᴅᴇɴᴄᴇ apply to AA')
local watermark = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Watermark')
local watermark_position_mode = ui.new_slider('AA', 'Anti-aimbot angles', 'Watermark position', 1, 8, 1, true, nil, 1)

-- V2 helpers were removed; V1 is the only active watermark style

ui.set_callback(watermark, function()
    local enabled = ui.get(watermark)
    local is_visuals = ui.get(current_tab) == 'Visuals'
    ui.set_visible(watermark_position_mode, enabled and is_visuals)
end)

local aspectratio = ui.new_slider('AA', 'Anti-aimbot angles', 'Aspect Ratio', 0, 200, 0, true, nil, 0.01, {[0] = "Off"})

-- Fast Doubletap
local enable_DT = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Fast Doubletap')
local doubletap_speed = ui.new_slider('AA', 'Anti-aimbot angles', 'DT Speed', 4, 24, 12, true, '', 1, {[0] = "Off"})
-- You can change min and max tick as you want, but I recommend not setting it too high, otherwise it may cause some problems.

local override_zoom_fov = ui_reference("Misc", "Miscellaneous", "Override zoom FOV")
local cache = ui.get(override_zoom_fov)
local scope_fov = ui_new_slider('AA', 'Anti-aimbot angles', "Second Zoom FOV", -0, 100, 0, true, '%', 1, {[0] = "Off"})

for i = 1, #anti_aim_states do
    anti_aim_settings[i] = {
        override_state = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Override ' .. string.lower(anti_aim_states[i])),
        pitch1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Pitch' .. anti_aim_different[i], 'Off', 'Default', 'Up', 'Down', 'Minimal', 'Random', 'Custom'),
        pitch2 = ui.new_slider('AA', 'Anti-aimbot angles', '\nPitch' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        yaw_base = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw base' .. anti_aim_different[i], 'Local view', 'At targets'),
        yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw' .. anti_aim_different[i], 'Off', '180', 'Spin', 'Static', '180 Z', 'Crosshair'),
        yaw2_left = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw left' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw2_right = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw right' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw2_randomize = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw randomize' .. anti_aim_different[i], 0, 180, 0, true, '°'),
        yaw_jitter1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Yaw jitter' .. anti_aim_different[i], 'Off', 'Offset', 'Center', 'Random', 'Skitter', 'Delay'),
        yaw_jitter2_left = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter left' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw_jitter2_right = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter right' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        yaw_jitter2_randomize = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter randomize' .. anti_aim_different[i], 0, 180, 0, true, '°'),
        yaw_jitter2_delay = ui.new_slider('AA', 'Anti-aimbot angles', 'Yaw jitter delay' .. anti_aim_different[i], 2, 10, 2, true, 't'),
        body_yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', 'Body yaw' .. anti_aim_different[i], 'Off', 'Opposite', 'Jitter', 'Static'),
        body_yaw2 = ui.new_slider('AA', 'Anti-aimbot angles', 'Body Yaw' .. anti_aim_different[i], -180, 180, 0, true, '°'),
        freestanding_body_yaw = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Freestanding body yaw' .. anti_aim_different[i]),
        roll = ui.new_slider('AA', 'Anti-aimbot angles', 'Roll' .. anti_aim_different[i], -45, 45, 0, true, '°'),
        force_defensive = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Force defensive' .. anti_aim_different[i]),
        defensive_anti_aimbot = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aB6B665FF✥ Defensive AA' .. anti_aim_different[i]),
        defensive_pitch = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aB6B665FF· Pitch' .. anti_aim_different[i]),
        defensive_pitch1 = ui.new_combobox('AA', 'Anti-aimbot angles', '\n· Pitch 2' .. anti_aim_different[i], 'Off', 'Default', 'Up', 'Down', 'Minimal', 'Random', 'Custom'),
        defensive_pitch2 = ui.new_slider('AA', 'Anti-aimbot angles', '\n· Pitch 3' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        defensive_pitch3 = ui.new_slider('AA', 'Anti-aimbot angles', '\n· Pitch 4' .. anti_aim_different[i], -89, 89, 0, true, '°'),
        defensive_yaw = ui.new_checkbox('AA', 'Anti-aimbot angles', '\aB6B665FF· Yaw' .. anti_aim_different[i]),
        defensive_yaw1 = ui.new_combobox('AA', 'Anti-aimbot angles', '· Yaw 1' .. anti_aim_different[i], '180', 'Spin', '180 Z', 'Sideways', 'Random'),
        defensive_yaw2 = ui.new_slider('AA', 'Anti-aimbot angles', '· Yaw 2' .. anti_aim_different[i], -180, 180, 0, true, '°')
    }
end

settings.warmup_disabler = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Warmup disabler')
settings.avoid_backstab = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Avoid backstab')
settings.safe_head_in_air = ui.new_checkbox('AA', 'Anti-aimbot angles', 'Safe head in air')
settings.manual_forward = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual forward')
settings.manual_right = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual right')
settings.manual_left = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Manual left')
settings.edge_yaw = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Edge yaw')
settings.freestanding = ui.new_hotkey('AA', 'Anti-aimbot angles', 'Freestanding')
settings.freestanding_conditions = ui.new_multiselect('AA', 'Anti-aimbot angles', '\nFreestanding', 'Standing', 'Moving', 'Slow motion', 'Crouching', 'In air')
settings.tweaks = ui.new_multiselect('AA', 'Anti-aimbot angles', '\nTweaks', 'Off jitter while freestanding', 'Off jitter on manual')

local data = {
    integers = {
        settings.anti_aim_state,
        anti_aim_settings[1].override_state, anti_aim_settings[2].override_state, anti_aim_settings[3].override_state, anti_aim_settings[4].override_state, anti_aim_settings[5].override_state, anti_aim_settings[6].override_state, anti_aim_settings[7].override_state, anti_aim_settings[8].override_state, anti_aim_settings[9].override_state, anti_aim_settings[10].override_state,
        anti_aim_settings[1].force_defensive, anti_aim_settings[2].force_defensive, anti_aim_settings[3].force_defensive, anti_aim_settings[4].force_defensive, anti_aim_settings[5].force_defensive, anti_aim_settings[6].force_defensive, anti_aim_settings[7].force_defensive, anti_aim_settings[8].force_defensive, anti_aim_settings[9].force_defensive, anti_aim_settings[10].force_defensive,
        anti_aim_settings[1].pitch1, anti_aim_settings[2].pitch1, anti_aim_settings[3].pitch1, anti_aim_settings[4].pitch1, anti_aim_settings[5].pitch1, anti_aim_settings[6].pitch1, anti_aim_settings[7].pitch1, anti_aim_settings[8].pitch1, anti_aim_settings[9].pitch1, anti_aim_settings[10].pitch1,
        anti_aim_settings[1].pitch2, anti_aim_settings[2].pitch2, anti_aim_settings[3].pitch2, anti_aim_settings[4].pitch2, anti_aim_settings[5].pitch2, anti_aim_settings[6].pitch2, anti_aim_settings[7].pitch2, anti_aim_settings[8].pitch2, anti_aim_settings[9].pitch2, anti_aim_settings[10].pitch2,
        anti_aim_settings[1].yaw_base, anti_aim_settings[2].yaw_base, anti_aim_settings[3].yaw_base, anti_aim_settings[4].yaw_base, anti_aim_settings[5].yaw_base, anti_aim_settings[6].yaw_base, anti_aim_settings[7].yaw_base, anti_aim_settings[8].yaw_base, anti_aim_settings[9].yaw_base, anti_aim_settings[10].yaw_base,
        anti_aim_settings[1].yaw1, anti_aim_settings[2].yaw1, anti_aim_settings[3].yaw1, anti_aim_settings[4].yaw1, anti_aim_settings[5].yaw1, anti_aim_settings[6].yaw1, anti_aim_settings[7].yaw1, anti_aim_settings[8].yaw1, anti_aim_settings[9].yaw1, anti_aim_settings[10].yaw1,
        anti_aim_settings[1].yaw2_left, anti_aim_settings[2].yaw2_left, anti_aim_settings[3].yaw2_left, anti_aim_settings[4].yaw2_left, anti_aim_settings[5].yaw2_left, anti_aim_settings[6].yaw2_left, anti_aim_settings[7].yaw2_left, anti_aim_settings[8].yaw2_left, anti_aim_settings[9].yaw2_left, anti_aim_settings[10].yaw2_left,
        anti_aim_settings[1].yaw2_right, anti_aim_settings[2].yaw2_right, anti_aim_settings[3].yaw2_right, anti_aim_settings[4].yaw2_right, anti_aim_settings[5].yaw2_right, anti_aim_settings[6].yaw2_right, anti_aim_settings[7].yaw2_right, anti_aim_settings[8].yaw2_right, anti_aim_settings[9].yaw2_right, anti_aim_settings[10].yaw2_right,
        anti_aim_settings[1].yaw2_randomize, anti_aim_settings[2].yaw2_randomize, anti_aim_settings[3].yaw2_randomize, anti_aim_settings[4].yaw2_randomize, anti_aim_settings[5].yaw2_randomize, anti_aim_settings[6].yaw2_randomize, anti_aim_settings[7].yaw2_randomize, anti_aim_settings[8].yaw2_randomize, anti_aim_settings[9].yaw2_randomize, anti_aim_settings[10].yaw2_randomize,
        anti_aim_settings[1].yaw_jitter1, anti_aim_settings[2].yaw_jitter1, anti_aim_settings[3].yaw_jitter1, anti_aim_settings[4].yaw_jitter1, anti_aim_settings[5].yaw_jitter1, anti_aim_settings[6].yaw_jitter1, anti_aim_settings[7].yaw_jitter1, anti_aim_settings[8].yaw_jitter1, anti_aim_settings[9].yaw_jitter1, anti_aim_settings[10].yaw_jitter1,
        anti_aim_settings[1].yaw_jitter2_left, anti_aim_settings[2].yaw_jitter2_left, anti_aim_settings[3].yaw_jitter2_left, anti_aim_settings[4].yaw_jitter2_left, anti_aim_settings[5].yaw_jitter2_left, anti_aim_settings[6].yaw_jitter2_left, anti_aim_settings[7].yaw_jitter2_left, anti_aim_settings[8].yaw_jitter2_left, anti_aim_settings[9].yaw_jitter2_left, anti_aim_settings[10].yaw_jitter2_left,
        anti_aim_settings[1].yaw_jitter2_right, anti_aim_settings[2].yaw_jitter2_right, anti_aim_settings[3].yaw_jitter2_right, anti_aim_settings[4].yaw_jitter2_right, anti_aim_settings[5].yaw_jitter2_right, anti_aim_settings[6].yaw_jitter2_right, anti_aim_settings[7].yaw_jitter2_right, anti_aim_settings[8].yaw_jitter2_right, anti_aim_settings[9].yaw_jitter2_right, anti_aim_settings[10].yaw_jitter2_right,
        anti_aim_settings[1].yaw_jitter2_randomize, anti_aim_settings[2].yaw_jitter2_randomize, anti_aim_settings[3].yaw_jitter2_randomize, anti_aim_settings[4].yaw_jitter2_randomize, anti_aim_settings[5].yaw_jitter2_randomize, anti_aim_settings[6].yaw_jitter2_randomize, anti_aim_settings[7].yaw_jitter2_randomize, anti_aim_settings[8].yaw_jitter2_randomize, anti_aim_settings[9].yaw_jitter2_randomize, anti_aim_settings[10].yaw_jitter2_randomize,
        anti_aim_settings[1].yaw_jitter2_delay, anti_aim_settings[2].yaw_jitter2_delay, anti_aim_settings[3].yaw_jitter2_delay, anti_aim_settings[4].yaw_jitter2_delay, anti_aim_settings[5].yaw_jitter2_delay, anti_aim_settings[6].yaw_jitter2_delay, anti_aim_settings[7].yaw_jitter2_delay, anti_aim_settings[8].yaw_jitter2_delay, anti_aim_settings[9].yaw_jitter2_delay, anti_aim_settings[10].yaw_jitter2_delay,
        anti_aim_settings[1].body_yaw1, anti_aim_settings[2].body_yaw1, anti_aim_settings[3].body_yaw1, anti_aim_settings[4].body_yaw1, anti_aim_settings[5].body_yaw1, anti_aim_settings[6].body_yaw1, anti_aim_settings[7].body_yaw1, anti_aim_settings[8].body_yaw1, anti_aim_settings[9].body_yaw1, anti_aim_settings[10].body_yaw1,
        anti_aim_settings[1].body_yaw2, anti_aim_settings[2].body_yaw2, anti_aim_settings[3].body_yaw2, anti_aim_settings[4].body_yaw2, anti_aim_settings[5].body_yaw2, anti_aim_settings[6].body_yaw2, anti_aim_settings[7].body_yaw2, anti_aim_settings[8].body_yaw2, anti_aim_settings[9].body_yaw2, anti_aim_settings[10].body_yaw2,
        anti_aim_settings[1].freestanding_body_yaw, anti_aim_settings[2].freestanding_body_yaw, anti_aim_settings[3].freestanding_body_yaw, anti_aim_settings[4].freestanding_body_yaw, anti_aim_settings[5].freestanding_body_yaw, anti_aim_settings[6].freestanding_body_yaw, anti_aim_settings[7].freestanding_body_yaw, anti_aim_settings[8].freestanding_body_yaw, anti_aim_settings[9].freestanding_body_yaw, anti_aim_settings[10].freestanding_body_yaw,
        anti_aim_settings[1].roll, anti_aim_settings[2].roll, anti_aim_settings[3].roll, anti_aim_settings[4].roll, anti_aim_settings[5].roll, anti_aim_settings[6].roll, anti_aim_settings[7].roll, anti_aim_settings[8].roll, anti_aim_settings[9].roll, anti_aim_settings[10].roll,
        anti_aim_settings[1].defensive_anti_aimbot, anti_aim_settings[2].defensive_anti_aimbot, anti_aim_settings[3].defensive_anti_aimbot, anti_aim_settings[4].defensive_anti_aimbot, anti_aim_settings[5].defensive_anti_aimbot, anti_aim_settings[6].defensive_anti_aimbot, anti_aim_settings[7].defensive_anti_aimbot, anti_aim_settings[8].defensive_anti_aimbot, anti_aim_settings[9].defensive_anti_aimbot, anti_aim_settings[10].defensive_anti_aimbot,
        anti_aim_settings[1].defensive_pitch, anti_aim_settings[2].defensive_pitch, anti_aim_settings[3].defensive_pitch, anti_aim_settings[4].defensive_pitch, anti_aim_settings[5].defensive_pitch, anti_aim_settings[6].defensive_pitch, anti_aim_settings[7].defensive_pitch, anti_aim_settings[8].defensive_pitch, anti_aim_settings[9].defensive_pitch, anti_aim_settings[10].defensive_pitch,
        anti_aim_settings[1].defensive_pitch1, anti_aim_settings[2].defensive_pitch1, anti_aim_settings[3].defensive_pitch1, anti_aim_settings[4].defensive_pitch1, anti_aim_settings[5].defensive_pitch1, anti_aim_settings[6].defensive_pitch1, anti_aim_settings[7].defensive_pitch1, anti_aim_settings[8].defensive_pitch1, anti_aim_settings[9].defensive_pitch1, anti_aim_settings[10].defensive_pitch1,
        anti_aim_settings[1].defensive_pitch2, anti_aim_settings[2].defensive_pitch2, anti_aim_settings[3].defensive_pitch2, anti_aim_settings[4].defensive_pitch2, anti_aim_settings[5].defensive_pitch2, anti_aim_settings[6].defensive_pitch2, anti_aim_settings[7].defensive_pitch2, anti_aim_settings[8].defensive_pitch2, anti_aim_settings[9].defensive_pitch2, anti_aim_settings[10].defensive_pitch2,
        anti_aim_settings[1].defensive_pitch3, anti_aim_settings[2].defensive_pitch3, anti_aim_settings[3].defensive_pitch3, anti_aim_settings[4].defensive_pitch3, anti_aim_settings[5].defensive_pitch3, anti_aim_settings[6].defensive_pitch3, anti_aim_settings[7].defensive_pitch3, anti_aim_settings[8].defensive_pitch3, anti_aim_settings[9].defensive_pitch3, anti_aim_settings[10].defensive_pitch3,
        anti_aim_settings[1].defensive_yaw, anti_aim_settings[2].defensive_yaw, anti_aim_settings[3].defensive_yaw, anti_aim_settings[4].defensive_yaw, anti_aim_settings[5].defensive_yaw, anti_aim_settings[6].defensive_yaw, anti_aim_settings[7].defensive_yaw, anti_aim_settings[8].defensive_yaw, anti_aim_settings[9].defensive_yaw, anti_aim_settings[10].defensive_yaw,
        anti_aim_settings[1].defensive_yaw1, anti_aim_settings[2].defensive_yaw1, anti_aim_settings[3].defensive_yaw1, anti_aim_settings[4].defensive_yaw1, anti_aim_settings[5].defensive_yaw1, anti_aim_settings[6].defensive_yaw1, anti_aim_settings[7].defensive_yaw1, anti_aim_settings[8].defensive_yaw1, anti_aim_settings[9].defensive_yaw1, anti_aim_settings[10].defensive_yaw1,
        anti_aim_settings[1].defensive_yaw2, anti_aim_settings[2].defensive_yaw2, anti_aim_settings[3].defensive_yaw2, anti_aim_settings[4].defensive_yaw2, anti_aim_settings[5].defensive_yaw2, anti_aim_settings[6].defensive_yaw2, anti_aim_settings[7].defensive_yaw2, anti_aim_settings[8].defensive_yaw2, anti_aim_settings[9].defensive_yaw2, anti_aim_settings[10].defensive_yaw2,
        settings.avoid_backstab,
        settings.safe_head_in_air,
        settings.freestanding_conditions,
        settings.tweaks, master_switch, console_filter, anim_breakerx, scope_fov, trashtalk, aspectratio, hitmarker, fastladder, clantagchanger, settings.warmup_disabler,
        enable_DT, doubletap_speed, confidence_checkbox, confidence_indicator, confidence_strength, confidence_apply_to_aa
    }
}

local function import(text)
    local status, config =
        pcall(
        function()
            return json.parse(base64.decode(text))
        end
    )

    if not status or status == nil then
        client.color_log(255, 0, 0, "+W.tech ~\0")
	    client.color_log(200, 200, 200, " error while importing!")
        return
    end

    if config ~= nil then
        for k, v in pairs(config) do
            k = ({[1] = 'integers'})[k]

            for k2, v2 in pairs(v) do
                if k == 'integers' then
                    ui.set(data[k][k2], v2)
                end
            end
        end
    end

    client.color_log(124, 252, 0, "+W.tech ~\0")
	client.color_log(200, 200, 200, " config successfully imported!")

end

-- Fast Doubletap function
local function superDT()
    if ui.get(enable_DT) then
        client.set_cvar("sv_maxusrcmdprocessticks", ui.get(doubletap_speed))
    end
end

client.set_event_callback("paint", superDT)

client.set_event_callback('setup_command', function(cmd)
    local self = entity.get_local_player()

    if entity.get_player_weapon(self) == nil then return end

    local using = false
    local anti_aim_on_use = false

    local inverted = entity.get_prop(self, "m_flPoseParameter", 11) * 120 - 60

    local is_planting = entity.get_prop(self, 'm_bInBombZone') == 1 and entity.get_classname(entity.get_player_weapon(self)) == 'CC4' and entity.get_prop(self, 'm_iTeamNum') == 2
    local CPlantedC4 = entity.get_all('CPlantedC4')[1]

    local eye_x, eye_y, eye_z = client.eye_position()
	local pitch, yaw = client.camera_angles()

    local sin_pitch = math.sin(math.rad(pitch))
	local cos_pitch = math.cos(math.rad(pitch))

	local sin_yaw = math.sin(math.rad(yaw))
	local cos_yaw = math.cos(math.rad(yaw))

    local direction_vector = {cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch}

    local fraction, entity_index = client.trace_line(self, eye_x, eye_y, eye_z, eye_x + (direction_vector[1] * 8192), eye_y + (direction_vector[2] * 8192), eye_z + (direction_vector[3] * 8192))

    if CPlantedC4 ~= nil then
        dist_to_c4 = vector(entity.get_prop(self, 'm_vecOrigin')):dist(vector(entity.get_prop(CPlantedC4, 'm_vecOrigin')))

        if entity.get_prop(CPlantedC4, 'm_bBombDefused') == 1 then dist_to_c4 = 56 end

        is_defusing = dist_to_c4 < 56 and entity.get_prop(self, 'm_iTeamNum') == 3
    end

    if entity_index ~= -1 then
        if vector(entity.get_prop(self, 'm_vecOrigin')):dist(vector(entity.get_prop(entity_index, 'm_vecOrigin'))) < 146 then
            using = entity.get_classname(entity_index) ~= 'CWorld' and entity.get_classname(entity_index) ~= 'CFuncBrush' and entity.get_classname(entity_index) ~= 'CCSPlayer'
        end
    end

    if cmd.in_use == 1 and not using and not is_planting and not is_defusing and ui.get(anti_aim_settings[10].override_state) then cmd.buttons = bit.band(cmd.buttons, bit.bnot(bit.lshift(1, 5))); anti_aim_on_use = true; state_id = 10 else if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == false and (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == false and ui.get(anti_aim_settings[9].override_state) then anti_aim_on_use = false; state_id = 9 else if (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and ui.get(anti_aim_settings[8].override_state) then anti_aim_on_use = false; state_id = 8 elseif (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and ui.get(anti_aim_settings[7].override_state) then anti_aim_on_use = false; state_id = 7 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and (entity.get_prop(self, 'm_flDuckAmount') > 0.8 or ui.get(reference.duck_peek_assist)) and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and ui.get(anti_aim_settings[6].override_state) then anti_aim_on_use = false; state_id = 6 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 and ui.get(anti_aim_settings[5].override_state) then anti_aim_on_use = false; state_id = 5 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == true and ui.get(anti_aim_settings[4].override_state) then anti_aim_on_use = false; state_id = 4 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == false and ui.get(anti_aim_settings[3].override_state) then anti_aim_on_use = false; state_id = 3 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 and entity.get_prop(self, 'm_flDuckAmount') < 0.8 and ui.get(anti_aim_settings[2].override_state) then anti_aim_on_use = false; state_id = 2 else anti_aim_on_use = false; state_id = 1 end end end
    if cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0 then freestanding_state_id = 5 elseif (entity.get_prop(self, 'm_flDuckAmount') > 0.8 or ui.get(reference.duck_peek_assist)) and bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 then freestanding_state_id = 4 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == true then freestanding_state_id = 3 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() > 2 and (ui.get(reference.slow_motion[1]) and ui.get(reference.slow_motion[2])) == false then freestanding_state_id = 2 elseif bit.band(entity.get_prop(self, 'm_fFlags'), 1) ~= 0 and vector(entity.get_prop(self, 'm_vecVelocity')):length() < 2 then freestanding_state_id = 1 end

    ui.set(settings.manual_forward, 'On hotkey')
    ui.set(settings.manual_right, 'On hotkey')
    ui.set(settings.manual_left, 'On hotkey')

    cmd.force_defensive = ui.get(anti_aim_settings[state_id].force_defensive)

    ui.set(reference.pitch[1], ui.get(anti_aim_settings[state_id].pitch1))
    ui.set(reference.pitch[2], ui.get(anti_aim_settings[state_id].pitch2))
    ui.set(reference.yaw_base, (direction == 180 or direction == 90 or direction == -90) and anti_aim_on_use == false and 'Local view' or ui.get(anti_aim_settings[state_id].yaw_base))
    ui.set(reference.yaw[1], (direction == 180 or direction == 90 or direction == -90) and anti_aim_on_use == false and '180' or ui.get(anti_aim_settings[state_id].yaw1))

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if inverted > 0 then
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw_jitter2_left) or 180

                last_press = globals.realtime()
            end
        else
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw_jitter2_right) or 180

                last_press = globals.realtime()
            end
        end
    else
        if inverted > 0 then
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw2_left) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw2_left) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw2_left) or 180

                last_press = globals.realtime()
            end
        else
            if ui.get(settings.manual_left) and last_press + 0.2 < globals.realtime() then
                direction = direction == -90 and ui.get(anti_aim_settings[state_id].yaw2_right) or -90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_right) and last_press + 0.2 < globals.realtime() then
                direction = direction == 90 and ui.get(anti_aim_settings[state_id].yaw2_right) or 90

                last_press = globals.realtime()
            elseif ui.get(settings.manual_forward) and last_press + 0.2 < globals.realtime() then
                direction = direction == 180 and ui.get(anti_aim_settings[state_id].yaw2_right) or 180

                last_press = globals.realtime()
            end
        end
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if math.random(0, 1) ~= 0 then
            yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
            yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
        else
            yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
            yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
        end

        if inverted > 0 then
            if yaw_jitter2_left == 180 then yaw_jitter2_left = -180 elseif yaw_jitter2_left == 90 then yaw_jitter2_left = 89 elseif yaw_jitter2_left == -90 then yaw_jitter2_left = -89 end

            if not (direction == 180 or direction == 90 or direction == -90) then direction = yaw_jitter2_left end
        else
            if yaw_jitter2_right == 180 then yaw_jitter2_right = -180 elseif yaw_jitter2_right == 90 then yaw_jitter2_right = 89 elseif yaw_jitter2_right == -90 then yaw_jitter2_right = -89 end

            if not (direction == 180 or direction == 90 or direction == -90) then direction = yaw_jitter2_right end
        end
    else
        if inverted > 0 then
            if math.random(0, 1) ~= 0 then yaw2_left = ui.get(anti_aim_settings[state_id].yaw2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) else yaw2_left = ui.get(anti_aim_settings[state_id].yaw2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) end

            if yaw2_left == 180 then yaw2_left = -180 elseif yaw2_left == 90 then yaw2_left = 89 elseif yaw2_left == -90 then yaw2_left = -89 end

            if not (direction == 90 or direction == -90 or direction == 180) then direction = yaw2_left end
        else
            if math.random(0, 1) ~= 0 then yaw2_right = ui.get(anti_aim_settings[state_id].yaw2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) else yaw2_right = ui.get(anti_aim_settings[state_id].yaw2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize)) end

            if yaw2_right == 180 then yaw2_right = -180 elseif yaw2_right == 90 then yaw2_right = 89 elseif yaw2_right == -90 then yaw2_right = -89 end

            if not (direction == 90 or direction == -90 or direction == 180) then direction = yaw2_right end
        end
    end

    if anti_aim_on_use == true then
        if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
            if inverted > 0 then
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                end
            else
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize))
                end
            end
        else
            if inverted > 0 then
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                end
            else
                if math.random(0, 1) ~= 0 then
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                else
                    anti_aim_on_use_direction = ui.get(anti_aim_settings[state_id].yaw2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw2_randomize))
                end
            end
        end
    end

    if direction > 180 or direction < -180 then direction = -180 end
    if anti_aim_on_use_direction > 180 or anti_aim_on_use_direction < -180 then anti_aim_on_use_direction = -180 end

    ui.set(reference.yaw[2], anti_aim_on_use == false and direction or anti_aim_on_use_direction)
    ui.set(reference.yaw_jitter[1], ((direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false or ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' or ui.get(anti_aim_settings[state_id].yaw1) == 'Off') and 'Off' or ui.get(anti_aim_settings[state_id].yaw_jitter1))

    if inverted > 0 then
        if math.random(0, 1) ~= 0 then yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) else yaw_jitter2_left = ui.get(anti_aim_settings[state_id].yaw_jitter2_left) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) end

        if yaw_jitter2_left > 180 or yaw_jitter2_left < -180 then yaw_jitter2_left = -180 end

        ui.set(reference.yaw_jitter[2], ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and yaw_jitter2_left or 0)
    else
        if math.random(0, 1) ~= 0 then yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) - math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) else yaw_jitter2_right = ui.get(anti_aim_settings[state_id].yaw_jitter2_right) + math.random(0, ui.get(anti_aim_settings[state_id].yaw_jitter2_randomize)) end

        if yaw_jitter2_right > 180 or yaw_jitter2_right < -180 then yaw_jitter2_right = -180 end

        ui.set(reference.yaw_jitter[2], ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and yaw_jitter2_right or 0)
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == true or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == true then
            ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or 'Static')
        else
            ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or 'Jitter')
        end
    else
        ui.set(reference.body_yaw[1], (direction == 180 or direction == 90 or direction == -90) and contains(settings.tweaks, 'Off jitter on manual') and anti_aim_on_use == false and 'Opposite' or ui.get(anti_aim_settings[state_id].body_yaw1))
    end

    if cmd.command_number % ui.get(anti_aim_settings[state_id].yaw_jitter2_delay) + 1 > ui.get(anti_aim_settings[state_id].yaw_jitter2_delay) - 1 then
        delayed_jitter = not delayed_jitter
    end

    if ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' then
        if (ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) == true or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2])) == true then
            ui.set(reference.body_yaw[2], delayed_jitter and -90 or 90)
        else
            ui.set(reference.body_yaw[2], -40)
        end
    else
        ui.set(reference.body_yaw[2], ui.get(anti_aim_settings[state_id].body_yaw2))
    end

    ui.set(reference.freestanding_body_yaw, ui.get(anti_aim_settings[state_id].yaw1) ~= 'Off' and ui.get(anti_aim_settings[state_id].yaw_jitter1) == 'Delay' and false or ui.get(anti_aim_settings[state_id].freestanding_body_yaw))
    ui.set(reference.roll, ui.get(anti_aim_settings[state_id].roll))

    if ui.get(anti_aim_settings[state_id].defensive_anti_aimbot) and is_defensive_active and ((ui.get(reference.double_tap[1]) and ui.get(reference.double_tap[2])) or (ui.get(reference.on_shot_anti_aim[1]) and ui.get(reference.on_shot_anti_aim[2]))) and not (direction == 180 or direction == 90 or direction == -90) then
        if ui.get(anti_aim_settings[state_id].defensive_pitch) then
            ui.set(reference.pitch[1], ui.get(anti_aim_settings[state_id].defensive_pitch1))

            if ui.get(anti_aim_settings[state_id].defensive_pitch1) == 'Random' then
                ui.set(reference.pitch[1], 'Custom')
                ui.set(reference.pitch[2], math.random(ui.get(anti_aim_settings[state_id].defensive_pitch2), ui.get(anti_aim_settings[state_id].defensive_pitch3)))
            else
                ui.set(reference.pitch[2], ui.get(anti_aim_settings[state_id].defensive_pitch2))
            end
        end

        if ui.get(anti_aim_settings[state_id].defensive_yaw) then
            ui.set(reference.yaw_jitter[1], 'Off')
            ui.set(reference.body_yaw[1], 'Opposite')

            if ui.get(anti_aim_settings[state_id].defensive_yaw1) == '180' then
                ui.set(reference.yaw[1], '180')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Spin' then
                ui.set(reference.yaw[1], 'Spin')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == '180 Z' then
                ui.set(reference.yaw[1], '180 Z')

                ui.set(reference.yaw[2], ui.get(anti_aim_settings[state_id].defensive_yaw2))
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Sideways' then
                ui.set(reference.yaw[1], '180')

                if cmd.command_number % 4 >= 2 then
                    ui.set(reference.yaw[2], math.random(85, 100))
                else
                    ui.set(reference.yaw[2], math.random(-100, -85))
                end
            elseif ui.get(anti_aim_settings[state_id].defensive_yaw1) == 'Random' then
                ui.set(reference.yaw[1], '180')

                ui.set(reference.yaw[2], math.random(-180, 180))
            end
        end
    end

    if ui.get(settings.safe_head_in_air) and (cmd.in_jump == 1 or bit.band(entity.get_prop(self, 'm_fFlags'), 1) == 0) and entity.get_prop(self, 'm_flDuckAmount') > 0.8 and (entity.get_classname(entity.get_player_weapon(self)) == 'CKnife' or entity.get_classname(entity.get_player_weapon(self)) == 'CWeaponTaser') and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        ui.set(reference.pitch[1], 'Down')
        ui.set(reference.yaw[1], '180')
        ui.set(reference.yaw[2], 0)
        ui.set(reference.yaw_jitter[1], 'Off')
        ui.set(reference.body_yaw[1], 'Off')
        ui.set(reference.roll, 0)
    end

    ui.set(reference.edge_yaw, ui.get(settings.edge_yaw) and anti_aim_on_use == false and true or false)

    if ui.get(settings.freestanding) and ((contains(settings.freestanding_conditions, 'Standing') and freestanding_state_id == 1) or (contains(settings.freestanding_conditions, 'Moving') and freestanding_state_id == 2) or (contains(settings.freestanding_conditions, 'Slow motion') and freestanding_state_id == 3) or (contains(settings.freestanding_conditions, 'Crouching') and freestanding_state_id == 4) or (contains(settings.freestanding_conditions, 'In air') and freestanding_state_id == 5)) and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        ui.set(reference.freestanding[1], true)
        ui.set(reference.freestanding[2], 'Always on')

        if contains(settings.tweaks, 'Off jitter while freestanding') then
            ui.set(reference.yaw[1], '180')
            ui.set(reference.yaw[2], 0)
            ui.set(reference.yaw_jitter[1], 'Off')
            ui.set(reference.body_yaw[1], 'Opposite')
            ui.set(reference.body_yaw[2], 0)
            ui.set(reference.freestanding_body_yaw, true)
        end
    else
        ui.set(reference.freestanding[1], false)
        ui.set(reference.freestanding[2], 'On hotkey')
    end

    if ui.get(settings.avoid_backstab) and anti_aim_on_use == false and not (direction == 180 or direction == 90 or direction == -90) then
        local players = entity.get_players(true)

        if players ~= nil then
            for i, enemy in pairs(players) do
                for h = 0, 18 do
                    local head_x, head_y, head_z = entity.hitbox_position(players[i], h)
                    local wx, wy = renderer.world_to_screen(head_x, head_y, head_z)
                    local fractions, entindex_hit = client.trace_line(self, eye_x, eye_y, eye_z, head_x, head_y, head_z)

                    if 250 >= vector(entity.get_prop(enemy, 'm_vecOrigin')):dist(vector(entity.get_prop(self, 'm_vecOrigin'))) and entity.is_alive(enemy) and entity.get_player_weapon(enemy) ~= nil and entity.get_classname(entity.get_player_weapon(enemy)) == 'CKnife' and (entindex_hit == players[i] or fractions == 1) and not entity.is_dormant(players[i]) then
                        ui.set(reference.yaw[1], '180')
                        ui.set(reference.yaw[2], -180)
                    end
                end
            end
        end
    end
end)

local function on_paint()
    if not ui.get(watermark) then return end
    local width, height = client.screen_size()

    -- Single V1-style watermark with animated text, position selected by slider (1-8)
    local me = entity.get_local_player()
    if me == nil then return end

    local rr,gg,bb = 87, 235, 61
    local r2, g2, b2, a2 = 55, 55, 55,255
    local highlight_fraction =  (globals.realtime() / 2 % 1.2 * 2) - 1.2
    local output = ""
    local text_to_draw = "+W T E C H"
    for idx = 1, #text_to_draw do
        local character = text_to_draw:sub(idx, idx)
        local character_fraction = idx / #text_to_draw
        local r1, g1, b1, a1 = 255, 255, 255, 255
        local highlight_delta = (character_fraction - highlight_fraction)
        if highlight_delta >= 0 and highlight_delta <= 1.4 then
            if highlight_delta > 0.7 then
            highlight_delta = 1.4 - highlight_delta
            end
            local r_fraction, g_fraction, b_fraction, a_fraction = r2 - r1, g2 - g1, b2 - b1
            r1 = r1 + r_fraction * highlight_delta / 0.8
            g1 = g1 + g_fraction * highlight_delta / 0.8
            b1 = b1 + b_fraction * highlight_delta / 0.8
        end
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, 255, text_to_draw:sub(idx, idx))
    end
    output = output .. ' \afa5757FF[DEBUG]'

    local r,g,b,a = 87, 235, 61
    local text_w, text_h = renderer.measure_text(nil, output)
    local margin = 16

    local mode = ui.get(watermark_position_mode) or 1
    local x, y

    if mode == 1 then
        -- left top
        x, y = margin, margin
    elseif mode == 2 then
        -- left center
        x, y = margin, (height - text_h) / 2
    elseif mode == 3 then
        -- left bottom
        x, y = margin, height - text_h - margin
    elseif mode == 4 then
        -- right top
        x, y = width - text_w - margin, margin
    elseif mode == 5 then
        -- right center
        x, y = width - text_w - margin, (height - text_h) / 2
    elseif mode == 6 then
        -- right bottom
        x, y = width - text_w - margin, height - text_h - margin
    elseif mode == 7 then
        -- center top
        x, y = (width - text_w) / 2, margin
    elseif mode == 8 then
        -- center bottom
        x, y = (width - text_w) / 2, height - text_h - margin
    else
        x, y = width - text_w - margin, margin
    end

    renderer.text(x, y, r, g, b, 255, "", 0, output)
end

client.set_event_callback('paint_ui', function()
    if entity.get_local_player() == nil then cheked_ticks = 0 end

    if ui.is_menu_open() then
        ui.set_visible(reference.pitch[1], false)
        ui.set_visible(reference.pitch[2], false)
        ui.set_visible(reference.yaw_base, false)
        ui.set_visible(reference.yaw[1], false)
        ui.set_visible(reference.yaw[2], false)
        ui.set_visible(reference.yaw_jitter[1], false)
        ui.set_visible(reference.yaw_jitter[2], false)
        ui.set_visible(reference.body_yaw[1], false)
        ui.set_visible(reference.body_yaw[2], false)
        ui.set_visible(reference.freestanding_body_yaw, false)
        ui.set_visible(reference.edge_yaw, false)
        ui.set_visible(reference.freestanding[1], false)
        ui.set_visible(reference.freestanding[2], false)
        ui.set_visible(reference.roll, false)
        ui.set_visible(settings.anti_aim_state, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.avoid_backstab, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.safe_head_in_air, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_forward, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_right, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.manual_left, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.edge_yaw, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.freestanding, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.warmup_disabler, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.freestanding_conditions, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(settings.tweaks, ui.get(current_tab) == 'Anti-Aim')
        ui.set_visible(trashtalk, ui.get(current_tab) == 'Misc')
        ui.set_visible(master_switch, ui.get(current_tab) == 'Misc')
        ui.set_visible(console_filter, ui.get(current_tab) == 'Visuals')
        ui.set_visible(anim_breakerx, ui.get(current_tab) == 'Misc')
        ui.set_visible(aspectratio, ui.get(current_tab) == 'Visuals')
        ui.set_visible(scope_fov, ui.get(current_tab) == 'Visuals')
        ui.set_visible(hitmarker, ui.get(current_tab) == 'Visuals')
        ui.set_visible(watermark, ui.get(current_tab) == 'Visuals')
        ui.set_visible(watermark_position_mode, ui.get(current_tab) == 'Visuals' and ui.get(watermark))
        ui.set_visible(fastladder, ui.get(current_tab) == 'Misc')
        ui.set_visible(clantagchanger, ui.get(current_tab) == 'Misc')
        ui.set_visible(enable_DT, ui.get(current_tab) == 'Misc')
        ui.set_visible(doubletap_speed, ui.get(current_tab) == 'Misc')
        ui.set_visible(confidence_checkbox, ui.get(current_tab) == 'Misc')
        ui.set_visible(confidence_indicator, ui.get(current_tab) == 'Misc' and ui.get(confidence_checkbox))
        ui.set_visible(confidence_strength, ui.get(current_tab) == 'Misc' and ui.get(confidence_checkbox))
        ui.set_visible(confidence_apply_to_aa, ui.get(current_tab) == 'Misc' and ui.get(confidence_checkbox))
        ui.set_visible(text1, ui.get(current_tab) == 'Home')
        ui.set_visible(text2, ui.get(current_tab) == 'Home')
        ui.set_visible(text3, ui.get(current_tab) == 'Home')

        for i = 1, #anti_aim_states do
            ui.set_visible(anti_aim_settings[i].override_state, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set(anti_aim_settings[1].override_state, true); ui.set_visible(anti_aim_settings[1].override_state, false)
            ui.set_visible(anti_aim_settings[i].force_defensive, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set_visible(anti_aim_settings[9].force_defensive, false)
            ui.set_visible(anti_aim_settings[i].pitch1,ui.get(current_tab) == 'Anti-Aim' and  ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].pitch2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].pitch1) == 'Custom')
            ui.set_visible(anti_aim_settings[i].yaw_base, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].yaw2_left, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw2_right, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw2_randomize, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].yaw_jitter1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_left, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_right, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_randomize, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Off')
            ui.set_visible(anti_aim_settings[i].yaw_jitter2_delay, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) == 'Delay')
            ui.set_visible(anti_aim_settings[i].body_yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].body_yaw2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and (ui.get(anti_aim_settings[i].body_yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].body_yaw1) ~= 'Opposite') and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].freestanding_body_yaw, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].body_yaw1) ~= 'Off' and ui.get(anti_aim_settings[i].yaw_jitter1) ~= 'Delay')
            ui.set_visible(anti_aim_settings[i].roll, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i])
            ui.set_visible(anti_aim_settings[i].defensive_anti_aimbot, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i]); ui.set_visible(anti_aim_settings[9].defensive_anti_aimbot, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot)); ui.set_visible(anti_aim_settings[9].defensive_pitch, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch)); ui.set_visible(anti_aim_settings[9].defensive_pitch1, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch) and (ui.get(anti_aim_settings[i].defensive_pitch1) == 'Random' or ui.get(anti_aim_settings[i].defensive_pitch1) == 'Custom')); ui.set_visible(anti_aim_settings[9].defensive_pitch2, false)
            ui.set_visible(anti_aim_settings[i].defensive_pitch3, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_pitch) and ui.get(anti_aim_settings[i].defensive_pitch1) == 'Random'); ui.set_visible(anti_aim_settings[9].defensive_pitch3, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw, ui.get(current_tab) == 'Anti-Aim' and  ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot)); ui.set_visible(anti_aim_settings[9].defensive_yaw, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw1, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_yaw)); ui.set_visible(anti_aim_settings[9].defensive_yaw1, false)
            ui.set_visible(anti_aim_settings[i].defensive_yaw2, ui.get(current_tab) == 'Anti-Aim' and ui.get(settings.anti_aim_state) == anti_aim_states[i] and ui.get(anti_aim_settings[i].defensive_anti_aimbot) and ui.get(anti_aim_settings[i].defensive_yaw) and (ui.get(anti_aim_settings[i].defensive_yaw1) == '180' or ui.get(anti_aim_settings[i].defensive_yaw1) == 'Spin' or ui.get(anti_aim_settings[i].defensive_yaw1) == '180 Z')); ui.set_visible(anti_aim_settings[9].defensive_yaw2, false)
        end
    end
end)

import_btn = ui.new_button("AA", "Anti-aimbot angles", "Import settings", function() import(clipboard.get()) end)
export_btn = ui.new_button("AA", "Anti-aimbot angles", "Export settings", function() 
    local code = {{}}

    for i, integers in pairs(data.integers) do
        table.insert(code[1], ui.get(integers))
    end

    clipboard.set(base64.encode(json.stringify(code)))
    client.color_log(124, 252, 0, "+W.tech ~\0")
	client.color_log(200, 200, 200, " config successfully exported!")
end)
default_btn = ui.new_button("AA", "Anti-aimbot angles", "Default Config", function() 
    import('W1siTW92aW5nIix0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLHRydWUsdHJ1ZSx0cnVlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLHRydWUsdHJ1ZSxmYWxzZSxmYWxzZSwiT2ZmIiwiTWluaW1hbCIsIk1pbmltYWwiLCJNaW5pbWFsIiwiTWluaW1hbCIsIk1pbmltYWwiLCJNaW5pbWFsIiwiTWluaW1hbCIsIk1pbmltYWwiLCJPZmYiLDAsMCwwLDAsMCwwLDAsMCwwLDAsIkxvY2FsIHZpZXciLCJBdCB0YXJnZXRzIiwiQXQgdGFyZ2V0cyIsIkF0IHRhcmdldHMiLCJBdCB0YXJnZXRzIiwiQXQgdGFyZ2V0cyIsIkF0IHRhcmdldHMiLCJBdCB0YXJnZXRzIiwiQXQgdGFyZ2V0cyIsIkxvY2FsIHZpZXciLCJPZmYiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCIxODAiLCJPZmYiLDAsOCwtMzMsLTE0LDAsLTE1LDAsMCw3LDAsMCw4LC0zMywtMTQsMCwtMTUsMCwwLDcsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLCJPZmYiLCJDZW50ZXIiLCJPZmZzZXQiLCJPZmZzZXQiLCJEZWxheSIsIk9mZnNldCIsIkRlbGF5IiwiRGVsYXkiLCJDZW50ZXIiLCJPZmYiLDAsNTQsNjgsNDAsLTI5LDUxLC0yNSwtMjMsNTAsMCwwLDU0LDY4LDQwLDQzLDUxLDQwLDQxLDUwLDAsMCwwLDUsNCwwLDMsMCwwLDAsMCwyLDIsMiwyLDQsMiw2LDQsMiwyLCJPZmYiLCJKaXR0ZXIiLCJKaXR0ZXIiLCJKaXR0ZXIiLCJPZmYiLCJKaXR0ZXIiLCJPZmYiLCJPZmYiLCJKaXR0ZXIiLCJPcHBvc2l0ZSIsMCwtNDAsLTQwLC00MCwwLC00MCwwLDAsLTQwLDAsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsZmFsc2UsdHJ1ZSwwLDAsMCwwLDAsMCwwLDAsMCwwLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLGZhbHNlLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLCJPZmYiLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCwwLDAsMCxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSxmYWxzZSwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwiMTgwIiwwLDAsMCwwLDAsMCwwLDAsMCwwLHRydWUsdHJ1ZSxbIlN0YW5kaW5nIiwiTW92aW5nIiwiQ3JvdWNoaW5nIl0sWyJPZmYgaml0dGVyIHdoaWxlIGZyZWVzdGFuZGluZyIsIk9mZiBqaXR0ZXIgb24gbWFudWFsIl0sdHJ1ZSx0cnVlLHRydWUsMzUsdHJ1ZSwxNTAsZmFsc2UsZmFsc2UsdHJ1ZSx0cnVlXV0=')
end)

client.set_event_callback('paint_ui', function()
    if entity.get_local_player() == nil then cheked_ticks = 0 end

    ui.set_visible(export_btn, ui.get(current_tab) == 'Home')
    ui.set_visible(import_btn, ui.get(current_tab) == 'Home')
    ui.set_visible(default_btn, ui.get(current_tab) == 'Home')
end)

ui.set_callback(console_filter, function()
    cvar.con_filter_text:set_string("cool text")
    cvar.con_filter_enable:set_int(1)
end)

--killsay
local killsay_pharases = {
    {'бля ебланоид хули ты делаешь не попал в мои приват аа сын сперматозоида ебанного', '1 хУеВыЙ уБлЮдОк'},
    {'СпИ хуЙнЯ ТуПаЯ', 'СпИ сЫн ХуЙнИ ВыЕбаЛ ТвоЮ сЕмьЮ'},
    {'1 ПиДоРаС ПоПаДаЕшЬ На МеДИю', '1 САБИНА СЛАЗИЕТ'},
    {'1 ХУЕСОС ТЫ ДИШИШЬ В ХУЙ ДЕНЧИКУ', 'ИзИ СтАрЫй ДоЛбАёБ хАхАхХа'},
    {'КонЧиЛ НА еБасОс ТвОЕй МатЕРи потому-что ОнА НЕ хоЧет ТакОгО же ВироДка КАК ты', 'EZ OWNED BY +W.TECH'},
    {'СпИ ВеЧнЫм снОм', 'OWNED BY SANCHEZj HVH LEGEND'},
    {'МоЛоДеЦ СДеЛаЛ мИнЕт КоРоЛю', 'бЛЯдоТа чТо ты дЕЛаеШь.ДУМал МЕНЯ уБИТь? хУЙ тебе сДОхНи От СпИдА пиДОрАс'},
    {'ZZZZZ СПИ МОЧА', '1 хуесос ты упал САБИНЕ В НОГИ ИДИ НАХУЙ УМАЛЕШОННЫЙ ПИДОР'},
    {'купи +w.tech а то колени твоей матери прострелил', 'купи +w.tech и не позорься хуесос'},
    {'В сОн НаХуЙ', 'СпИ вЫеБаЛ тВоЮ мАтЬ'},
    {'1 нИкЧеМнЫй ПиДоРаС', '1 гЛуПыЙ ПиДоРаС'},
    {'1 OwNeD bY +W TeCh', '1 СсаНыЙ бИч'},
    {'ПрИкУпИ +W tEcH а То ПаДаЕшЬ', '1 СпИ РоТоВыЕбАнЫй ХуЕсОс'},
    {'1 ШаЛаВа На КоЛеНи', 'О нЕт ЭтО чУдИщЕ оПяТь пАдАеТ нА мОй ДиК уЖааС'}
}
    
local death_say = {
    {'пиздец че я за хуйню купил', 'лучше бы +W.tech купил бля'},
    {'ну фу', 'хуесос'},
    {'что ты делаешь', 'моча умалишенная'},
    {'бля', 'я стрелял вообще или че?'},
    {'чит подвел'},
    {'БЛЯЯЯЯЯЯЯЯЯЯЯТЬ', 'как же ты меня заебал'},
    {'ну и зачем', 'дал бы клип', 'пиздец клоун'},
    {'ахахахах', 'ну да', 'опять сын шлюхи убил бестолковый'},
    {'м', 'пон)', 'найс чит'},
    {'да блять', 'какой джиттер поставить сука'},
    {'ну фу', 'ублюдок', 'ебаный'},
    {'да сука', 'где тимейты блять', 'как же сука они меня бесят'},
    {'lf ,kznm', 'да блять', 'опять я мисснул'},
    {'да блять', 'ало', 'я вообще стрелять буду нет'},
    {'хех', 'ты сам то хоть понял', 'как меня убил'},
    {'сука', 'опять по дезу ебаному'},
    {'бля', 'клиентнуло', 'лаки'},
    {'понятно', 'ик ак ты так играешь', 'еблан бестолковый'},
    {'ну блять', 'он просто пошел', 'пиздец'},
    {'&', 'и че это', 'откуда ты меня убил?'},
    {'тварь', 'ебаная', 'ЧТО ТЫ ДЕЛАЕШЬ'},
    {'YE LF', 'ну да', 'хуесос', 'норм играешь'},
    {'сочник ебаный', 'как же ты меня заебал уже', 'что ты делаешь'},
    {'хуевый без скита', 'как ты меня убиваешь с пастой своей'},
    {'подпивас ебаный', 'как же ты меня переиграл'},
    {'бля', 'признаю, переиграл'},
    {'как ты меня убиваешь', 'ебаный owosh'},
    {'дефектус че ты делаешь', 'пиздец'},
    {'хуйсосик анимешный', 'как ты убиваешь', 'эт пздц'},
    {'бля ну бро', 'посмотри на мою команду', 'это пзиидец'},
    {'ммм', 'хуесосы бездарные в команде'},
    {'ik.[f', 'шлюха пошла нахуй'},
    {'ndfhm t,fyfz', 'тварь ебаная как же ты меня бесишь'},
    {'фу нахуй', 'опять в бекшут'},
    {'только так и умеешь да?', 'блядь ебаная'},
    {'нахуй ты меня трешкаешь', 'шлюха ебаная'},
    {'ну повезло тебе', 'дальше то что хуесос'},
    {'ебанная ты мразь', 'которая мне все проебала'},
    {'ujcgjlb', 'господи', 'мразь убогая'},
    {'хахахах', 'ну бля заебись фристенд в чите)'},
    {'фу ты заебал конч'},
    {')', 'хорош)'},
    {'норм трекаешь', 'ублюдина'},
    {'а че', 'хайдшоты на фд уже не работают?'}
}

    
client.set_event_callback('player_death', function(e)
    delayed_msg = function(delay, msg)
        return client.delay_call(delay, function() client.exec('say ' .. msg) end)
    end

    local delay = 0.3
    local me = entity_get_local_player()
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)

    local killsay_delay = 0
    local deathsay_delay = 0

    if entity_get_local_player() == nil then return end

    gamerulesproxy = entity.get_all("CCSGameRulesProxy")[1]
    warmup = entity.get_prop(gamerulesproxy,"m_bWarmupPeriod")
    if warmup == 1 then return end

    if not ui.get(trashtalk) then return end

    if (victim ~= attacker and attacker == me) then
        local phase_block = killsay_pharases[math.random(1, #killsay_pharases)]

            for i=1, #phase_block do
                local phase = phase_block[i]
                local interphrase_delay = #phase_block[i]/24*delay
                killsay_delay = killsay_delay + interphrase_delay

                delayed_msg(killsay_delay, phase)
            end
        end
            
    if (victim == me and attacker ~= me) then
        local phase_block = death_say[math.random(1, #death_say)]

        for i=1, #phase_block do
            local phase = phase_block[i]
            local interphrase_delay
