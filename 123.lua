local obex_data = obex_fetch and obex_fetch() or {username = 'User', build = 'BETA', discord=''}

-- Добавляем модуль HTTP для получения данных с Pastebin
local http = require("gamesense/http") or nil

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

client.set_event_callback("paint",function()
    visual_functions.start_intro()
end)

-- Вызываем загрузку имени при запуске скрипта
client.delay_call(0, function()
    if http then
        visual_functions:fetch_username_from_pastebin()
    end
end)
