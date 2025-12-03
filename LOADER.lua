-- Фейковый скрипт - показывает что-то для отвлечения

client.color_log(0, 255, 0, "[Script] Инициализация...")
client.color_log(0, 255, 255, "[Script] Загрузка модулей...")

ui.new_label("LUA", "B", "═══ Demo Script ═══")
ui.new_label("LUA", "B", "Статус: Активен")
ui.new_checkbox("LUA", "B", "Запустить")
ui.new_checkbox("LUA", "B", "Отгрузить")

client.color_log(0, 255, 0, "[Script] Готов к работе!")

-- Можно добавить какой-то простой функционал для правдоподобности
client.set_event_callback("paint", function()
    local sw, sh = client.screen_size()
    renderer.text(sw - 100, 10, 255, 255, 255, 255, "", 0, "Demo Active")
end)
