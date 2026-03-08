--[[
    adonis_bypass.lua
    Empire Clash — Adonis Anti-Cheat Bypass
    ========================================
    
    HOW IT WORKS:
    Adonis Anti_Cheat.luau stores its detection handlers in internal tables
    that have keys like "indexInstance", "newindexInstance", "namecallInstance".
    When any detection fires, it calls Detected("kick", reason) or 
    Detected("crash", reason) which dispatches through these tables.
    
    We scan the garbage collector for these tables and inject a custom
    handler for "kick" and "crash" that just waits forever (12+ years),
    effectively making every single detection a no-op.
    
    This neutralizes ALL Adonis detections at once:
    - MainDetection (log scanner for exploit strings)
    - HumanoidState (noclip via StrafingNoPhysics)
    - Speed (GetRealPhysicsFPS check)
    - AntiAntiIdle
    - VirtualUser/VirtualInputManager service check  
    - Proxy metamethod traps
    - HopperBin/BuildingTools detection
    - Sound ID checks
    - And any future checks they add
--]]

-- ─────────────────────────────────────────────────────────────────────────────
-- PRIMARY BYPASS: Patch Adonis dispatch tables via getgc
-- ─────────────────────────────────────────────────────────────────────────────
local _bypassed = false

local function bypassAdonis()
    if not getgc then
        warn("[AdonisBypass] getgc not available on this executor")
        return false
    end
    
    local patched = 0
    for _, value in pairs(getgc(true)) do
        if typeof(value) == "table" then
            if rawget(value, "indexInstance") 
                or rawget(value, "newindexInstance") 
                or rawget(value, "namecallInstance") 
                or rawget(value, "newIndexInstance") 
            then
                -- Inject infinite-wait handlers for kick and crash actions.
                -- When Adonis dispatches Detected("kick", ...) or 
                -- Detected("crash", ...), it hits our handler instead and
                -- just blocks forever (387420489s ≈ 12.3 years).
                value.tvk = {
                    "kick",
                    function()
                        return task.wait(387420489)
                    end
                }
                patched += 1
            end
        end
    end
    
    _bypassed = patched > 0
    return _bypassed
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FALLBACK: If getgc didn't find the tables (Adonis not loaded yet),
-- keep retrying for up to 15 seconds.
-- ─────────────────────────────────────────────────────────────────────────────
if bypassAdonis() then
    print("[AdonisBypass] ✓ Patched Adonis dispatch tables immediately")
else
    task.spawn(function()
        local deadline = tick() + 15
        while tick() < deadline and not _bypassed do
            task.wait(0.5)
            bypassAdonis()
        end
        if _bypassed then
            print("[AdonisBypass] ✓ Patched Adonis dispatch tables (deferred)")
        else
            warn("[AdonisBypass] ⚠ Could not find Adonis tables — may not be loaded")
        end
    end)
end
