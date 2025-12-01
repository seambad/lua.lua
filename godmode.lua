-- 3-WAY AA + SLOW JITTER + BODY BREAKER GODMODE (HrisitoSense / Gamesense 2026)
-- 3 Ways: Left → Freestand → Right + Slow Jitter
-- BODY BREAKER: LBY + Body Pitch/Yaw POSES конфликт каждый тик (ломает body resolve 100%)

local enable = ui.new_checkbox("AA", "Anti-aimbot angles", "3-Way AA + Slow Jitter + Body Breaker")

local desync_amt = ui.new_slider("AA", "Anti-aimbot angles", "Desync Amount", 55, 65, 60)
local cycle_ms   = ui.new_slider("AA", "Anti-aimbot angles", "3-Way Cycle Speed (ms)", 100, 400, 250)
local jitter_amt = ui.new_slider("AA", "Anti-aimbot angles", "Slow Jitter Amount", 5, 20, 12)
local jitter_ms  = ui.new_slider("AA", "Anti-aimbot angles", "Jitter Speed (ms)", 300, 800, 500)

local way_idx = 1
local ways = {-1, 0, 1}  -- Left, Freestand, Right
local last_cycle = 0

local jitter_val = 0
local last_jitter = 0

local function on_setup_command(cmd)
    if not ui.get(enable) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local rt = globals.realtime()

    -- 3-WAY CYCLE
    if rt - last_cycle >= (ui.get(cycle_ms) / 1000) then
        way_idx = (way_idx % 3) + 1
        last_cycle = rt
    end

    -- SLOW JITTER
    if rt - last_jitter >= (ui.get(jitter_ms) / 1000) then
        jitter_val = math.random(-ui.get(jitter_amt), ui.get(jitter_amt))
        last_jitter = rt
    end

    -- BASE BACKWARDS
    local real_yaw = entity.get_prop(me, "m_angEyeAngles[1]") or 0
    local base_yaw = real_yaw + 180

    -- 3-WAY + JITTER
    local way_offset = ways[way_idx] * ui.get(desync_amt)
    cmd.yaw = base_yaw + way_offset + jitter_val

    -- SAFE PITCH
    local pitches = {0, 89, 108}
    cmd.pitch = pitches[math.random(1, 3)] + math.random(-3, 3)

    -- Rand defensive
    if math.random(1, 10) == 1 then
        cmd.force_defensive = true
    end
end

-- BODY BREAKER + FULL ANIMATION CHAOS
client.set_event_callback("net_update_end", function()
    if not ui.get(enable) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local rt = globals.realtime()
    math.randomseed(rt * 1000000 + globals.tickcount())

    -- BODY BREAKER #1: LBY полный рандом ±180 каждый тик
    entity.set_prop(me, "m_flLowerBodyYawTarget", math.random(-180, 180))

    -- BODY BREAKER #2: Body Pitch (11) — наклон туловища RAND (ломает chest/stomach)
    entity.set_prop(me, "m_flPoseParameter", math.random(), 11)

    -- BODY BREAKER #3: Body Yaw (12) — поворот туловища RAND + конфликт с head_yaw (8)
    local body_yaw = math.random()
    entity.set_prop(me, "m_flPoseParameter", body_yaw, 12)           -- body_yaw RAND
    entity.set_prop(me, "m_flPoseParameter", 1 - body_yaw, 8)        -- head_yaw OPPOSITE

    -- EyeAngles RAND
    entity.set_prop(me, "m_angEyeAngles[0]", math.random(0, 108))
    entity.set_prop(me, "m_angEyeAngles[1]", math.random(-180, 180))
    entity.set_prop(me, "m_angEyeAngles[2]", math.random(-40, 40))

    -- Остальные poses хаос
    for i = 0, 23 do
        if i ~= 8 and i ~= 11 and i ~= 12 then
            entity.set_prop(me, "m_flPoseParameter", math.random(), i)
        end
    end
end)

client.set_event_callback("setup_command", on_setup_command)