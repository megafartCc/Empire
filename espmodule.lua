local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local V2 = Vector2.new
local CF = CFrame.new
local C3 = Color3.fromRGB

local M = {}
M.BoxEnabled     = false
M.NameEnabled    = false
M.HealthEnabled  = false
M.TracersEnabled = false
M.SkeletonEnabled = false
M.TeamEnabled    = false
M.RoleEnabled    = false
M.HeldItemEnabled = false
M.AnimalEnabled = false
M.MaxDist = 1000
M.OreEnabledByName = {}
M.ResourceEnabledByName = {}

local tracked = {}
local oreTracked = {}
local resourceTracked = {}
local animalTracked = {}
local oreTypes = {}
local resourceTypes = {}
local oreNodeToType = {}
local resourceNodeToType = {}
local oreColors = {
    Coal = C3(165, 165, 165),
    Gold = C3(255, 220, 65),
    Iron = C3(185, 210, 255),
}
local resourceColors = {
    Wood = C3(142, 102, 74),
    Wheat = C3(232, 214, 118),
    Raspberries = C3(238, 88, 123),
    Blueberries = C3(106, 161, 255),
    Blackberries = C3(137, 112, 201),
}
local animalColors = {
    Deer = C3(197, 155, 109),
    Rabbit = C3(238, 238, 238),
    Bear = C3(106, 84, 70),
    Wolf = C3(171, 171, 171),
    Horse = C3(152, 119, 89),
    Boar = C3(130, 92, 79),
}

local function oreAddType(name)
    if type(name) ~= "string" or name == "" then return end
    if M.OreEnabledByName[name] ~= nil then return end
    M.OreEnabledByName[name] = false
    table.insert(oreTypes, name)
end

local function resourceAddType(name)
    if type(name) ~= "string" or name == "" then return end
    if M.ResourceEnabledByName[name] ~= nil then return end
    M.ResourceEnabledByName[name] = false
    table.insert(resourceTypes, name)
end

local function oreMapNode(nodeName, oreName)
    if type(nodeName) ~= "string" or nodeName == "" then return end
    if type(oreName) ~= "string" or oreName == "" then return end
    oreNodeToType[string.lower(nodeName)] = oreName
    oreAddType(oreName)
end

local function resourceMapNode(nodeName, resourceName)
    if type(nodeName) ~= "string" or nodeName == "" then return end
    if type(resourceName) ~= "string" or resourceName == "" then return end
    resourceNodeToType[string.lower(nodeName)] = resourceName
    resourceAddType(resourceName)
end

local function loadGatheringConfig()
    local ok, config = pcall(function()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local module = modules and modules:FindFirstChild("ResourceNodeConfig")
        if module then
            return require(module)
        end
        return nil
    end)

    if ok and type(config) == "table" then
        for nodeName, info in pairs(config) do
            if type(nodeName) == "string" and type(info) == "table" then
                local toolType = tostring(info.ToolType or "")
                local nodeTypeName = info.ResourceName or info.NodeName or nodeName
                if type(nodeTypeName) == "string" and nodeTypeName ~= "" then
                    if toolType == "Pickaxe" then
                        oreMapNode(nodeName, nodeTypeName)
                    else
                        resourceMapNode(nodeName, nodeTypeName)
                    end
                end
            end
        end
    end

    if next(oreNodeToType) == nil then
        oreMapNode("coal node", "Coal")
        oreMapNode("gold node", "Gold")
        oreMapNode("iron node", "Iron")
    end

    if next(resourceNodeToType) == nil then
        resourceMapNode("tree", "Wood")
        resourceMapNode("tree1", "Wood")
        resourceMapNode("tree2", "Wood")
        resourceMapNode("tree3", "Wood")
        resourceMapNode("tree4", "Wood")
        resourceMapNode("tree5", "Wood")
        resourceMapNode("tree6", "Wood")
        resourceMapNode("tree7", "Wood")
        resourceMapNode("tree8", "Wood")
        resourceMapNode("redwood tree1", "Wood")
        resourceMapNode("redwood tree2", "Wood")
        resourceMapNode("redwood tree3", "Wood")
        resourceMapNode("wheat", "Wheat")
        resourceMapNode("blueberry bush", "Blueberries")
        resourceMapNode("blackberry bush", "Blackberries")
        resourceMapNode("raspberry bush", "Raspberries")
        resourceMapNode("snowberry bush", "Raspberries")
    end

    table.sort(oreTypes)
    table.sort(resourceTypes)
end
loadGatheringConfig()

local function resolveOreType(node)
    if not node or not node.Name then return nil end
    local key = string.lower(node.Name)
    local ore = oreNodeToType[key]
    if ore then return ore end
    if string.find(key, "coal", 1, true) then return "Coal" end
    if string.find(key, "gold", 1, true) then return "Gold" end
    if string.find(key, "iron", 1, true) then return "Iron" end
    return nil
end

local function resolveResourceType(node)
    if not node or not node.Name then return nil end
    local key = string.lower(node.Name)
    local resourceName = resourceNodeToType[key]
    if resourceName then return resourceName end
    if oreNodeToType[key] then return nil end
    if string.find(key, "tree", 1, true) then return "Wood" end
    if string.find(key, "wheat", 1, true) then return "Wheat" end
    if string.find(key, "blueberry", 1, true) then return "Blueberries" end
    if string.find(key, "blackberry", 1, true) then return "Blackberries" end
    if string.find(key, "raspberry", 1, true) or string.find(key, "snowberry", 1, true) then
        return "Raspberries"
    end
    return nil
end

local function resolveAnimalName(rootPart)
    if not rootPart then return nil end
    local model = rootPart.Parent
    if not model or not model.Parent then return nil end
    if model.Name == "HumanoidModel" then return nil end

    local raw = nil
    for _, inst in ipairs({ model, rootPart }) do
        for _, attrName in ipairs({ "AnimalType", "Species", "Type", "Animal", "HorseType" }) do
            local attr = inst:GetAttribute(attrName)
            if type(attr) == "string" and attr ~= "" then
                raw = attr
                break
            end
        end
        if raw then break end
    end
    if not raw then
        raw = model.Name
    end
    if type(raw) ~= "string" or raw == "" then
        return nil
    end

    local key = string.lower(raw)
    if string.find(key, "deer", 1, true) then return "Deer" end
    if string.find(key, "rabbit", 1, true) then return "Rabbit" end
    if string.find(key, "bear", 1, true) then return "Bear" end
    if string.find(key, "wolf", 1, true) then return "Wolf" end
    if string.find(key, "horse", 1, true) or string.find(key, "donkey", 1, true) then return "Horse" end
    if string.find(key, "boar", 1, true) then return "Boar" end

    local clean = string.gsub(raw, "HumanoidModel", "")
    clean = string.gsub(clean, "^%s+", "")
    clean = string.gsub(clean, "%s+$", "")
    if clean == "" then
        return nil
    end
    return clean
end

local function nodePos(node)
    if not node or not node.Parent then return nil end
    if node:IsA("BasePart") then
        return node.Position
    end
    if node:IsA("Model") then
        local p = node.PrimaryPart or node:FindFirstChildWhichIsA("BasePart", true)
        if p then return p.Position end
        local ok, pivot = pcall(function() return node:GetPivot() end)
        if ok and pivot then return pivot.Position end
    end
    local part = node:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function hideOre(data)
    if data and data.text then
        data.text.Visible = false
    end
end

local function hideResource(data)
    if data and data.text then
        data.text.Visible = false
    end
end

local function hideAnimal(data)
    if data and data.text then
        data.text.Visible = false
    end
end

local function untrackOre(node)
    local data = oreTracked[node]
    if not data then return end
    pcall(function()
        if data.text then
            data.text:Remove()
        end
    end)
    oreTracked[node] = nil
end

local function untrackResource(node)
    local data = resourceTracked[node]
    if not data then return end
    pcall(function()
        if data.text then
            data.text:Remove()
        end
    end)
    resourceTracked[node] = nil
end

local function untrackAnimal(node)
    local data = animalTracked[node]
    if not data then return end
    pcall(function()
        if data.text then
            data.text:Remove()
        end
    end)
    animalTracked[node] = nil
end

local function trackOre(node)
    if oreTracked[node] then return end
    local oreName = resolveOreType(node)
    if not oreName then return end

    local data = { oreName = oreName, text = nil }
    local ok = pcall(function()
        local t = Drawing.new("Text")
        t.Visible = false
        t.Size = 13
        t.Center = true
        t.Outline = true
        t.Color = oreColors[oreName] or C3(255, 255, 255)
        data.text = t
    end)
    if not ok or not data.text then return end
    oreTracked[node] = data
end

local function trackResource(node)
    if resourceTracked[node] then return end
    local resourceName = resolveResourceType(node)
    if not resourceName then return end

    local data = { resourceName = resourceName, text = nil }
    local ok = pcall(function()
        local t = Drawing.new("Text")
        t.Visible = false
        t.Size = 13
        t.Center = true
        t.Outline = true
        t.Color = resourceColors[resourceName] or C3(255, 255, 255)
        data.text = t
    end)
    if not ok or not data.text then return end
    resourceTracked[node] = data
end

local function trackAnimal(rootPart)
    if animalTracked[rootPart] then return end
    if not rootPart or not rootPart:IsA("BasePart") then return end
    local animalName = resolveAnimalName(rootPart)
    if not animalName then return end

    local data = { animalName = animalName, text = nil }
    local ok = pcall(function()
        local t = Drawing.new("Text")
        t.Visible = false
        t.Size = 13
        t.Center = true
        t.Outline = true
        t.Color = animalColors[animalName] or C3(255, 255, 255)
        data.text = t
    end)
    if not ok or not data.text then return end
    animalTracked[rootPart] = data
end

for _, node in ipairs(CollectionService:GetTagged("ResourceNode")) do
    pcall(trackOre, node)
    pcall(trackResource, node)
end

CollectionService:GetInstanceAddedSignal("ResourceNode"):Connect(function(node)
    pcall(trackOre, node)
    pcall(trackResource, node)
end)

CollectionService:GetInstanceRemovedSignal("ResourceNode"):Connect(function(node)
    pcall(untrackOre, node)
    pcall(untrackResource, node)
end)

for _, rootPart in ipairs(CollectionService:GetTagged("AnimalRootPart")) do
    pcall(trackAnimal, rootPart)
end

CollectionService:GetInstanceAddedSignal("AnimalRootPart"):Connect(function(rootPart)
    pcall(trackAnimal, rootPart)
end)

CollectionService:GetInstanceRemovedSignal("AnimalRootPart"):Connect(function(rootPart)
    pcall(untrackAnimal, rootPart)
end)

local function w2s(p)
    local v, on = Camera:WorldToViewportPoint(p)
    return V2(v.X, v.Y), on, v.Z
end

local function alive(p)
    local c = p and p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

-- ──────────────────────────────────────────────────────────────────────────────
-- HEALTH CACHE
-- Empire Clash uses Knit's DamageService to apply damage server-side.
-- Humanoid.Health is still replicated, BUT the HealthChanged signal fires
-- reliably with the new value before the next Heartbeat catches it.
-- We cache hp/maxHp per player and reconnect on every CharacterAdded so we
-- always have a fresh connection regardless of respawn.
-- ──────────────────────────────────────────────────────────────────────────────
local function connectHpCache(plr)
    local d = tracked[plr]
    if not d then return end

    -- Disconnect old HP listener if any
    if d.hpConns then
        for _, c in ipairs(d.hpConns) do pcall(function() c:Disconnect() end) end
    end
    d.hpConns = {}

    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Empire Clash custom health Attributes reading
    local function readHp()
        local attrHp = hum:GetAttribute("Health")
        if attrHp then
            d.cachedHp    = attrHp
            d.cachedMaxHp = hum:GetAttribute("MaxHealth") or 100
        else
            d.cachedHp    = hum.Health
            d.cachedMaxHp = math.max(hum.MaxHealth, 1)
        end
    end

    -- Seed with current values immediately
    readHp()

    -- Listen for every health change - this fires instantly when DamageService
    -- applies damage, long before the next Heartbeat poll would notice.
    table.insert(d.hpConns, hum:GetAttributeChangedSignal("Health"):Connect(readHp))
    table.insert(d.hpConns, hum.HealthChanged:Connect(readHp))
end

local function getRoleName(plr)
    if not plr then return nil end
    local leaderstats = plr:FindFirstChild("leaderstats")
    local classValue = leaderstats and leaderstats:FindFirstChild("Class")
    local role = classValue and tostring(classValue.Value) or nil
    local disguised = plr:GetAttribute("DisguisedClass")
    if type(disguised) == "string" and disguised ~= "" then
        role = disguised
    end
    if type(role) == "string" and role ~= "" then
        return role
    end
    return nil
end

local function make(plr)
    if plr == LP or tracked[plr] then return end
    local d = {}
    d.cachedHp    = 100
    d.cachedMaxHp = 100
    d.hpConns     = nil

    pcall(function()
        d.box = {}
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Visible = false
            l.Color = C3(255,255,255)
            l.Thickness = 1
            d.box[i] = l
        end

        d.tracer = Drawing.new("Line")
        d.tracer.Visible = false
        d.tracer.Color = C3(255,255,255)
        d.tracer.Thickness = 1

        d.name = Drawing.new("Text")
        d.name.Visible = false
        d.name.Color = C3(255,255,255)
        d.name.Size = 14
        d.name.Center = true
        d.name.Outline = true

        d.team = Drawing.new("Text")
        d.team.Visible = false
        d.team.Color = C3(255,255,255)
        d.team.Size = 13
        d.team.Center = false
        d.team.Outline = true

        d.role = Drawing.new("Text")
        d.role.Visible = false
        d.role.Color = C3(255,255,255)
        d.role.Size = 12
        d.role.Center = false
        d.role.Outline = true

        -- HP bar: background (black, thick) + fill (green→red)
        d.hpBg = Drawing.new("Line")
        d.hpBg.Visible = false
        d.hpBg.Color = C3(0,0,0)
        d.hpBg.Thickness = 4

        d.hpFill = Drawing.new("Line")
        d.hpFill.Visible = false
        d.hpFill.Thickness = 3

        -- HP label showing exact value (e.g. "87 HP")
        d.hpLabel = Drawing.new("Text")
        d.hpLabel.Visible = false
        d.hpLabel.Color = C3(255,255,255)
        d.hpLabel.Size = 11
        d.hpLabel.Center = true
        d.hpLabel.Outline = true

        d.skel = {}
        d.skelBuilt = false

        d.heldItem = Drawing.new("Text")
        d.heldItem.Visible = false
        d.heldItem.Color = C3(255,200,0)
        d.heldItem.Size = 13
        d.heldItem.Center = true
        d.heldItem.Outline = true
    end)

    tracked[plr] = d
    -- Seed HP cache for the current character (if already spawned)
    connectHpCache(plr)
end

local function nuke(plr)
    local d = tracked[plr]
    if not d then return end
    pcall(function()
        if d.hpConns then
            for _, c in ipairs(d.hpConns) do pcall(function() c:Disconnect() end) end
        end
        for _, l in ipairs(d.box or {}) do l:Remove() end
        if d.tracer   then d.tracer:Remove()   end
        if d.name     then d.name:Remove()     end
        if d.team     then d.team:Remove()     end
        if d.role     then d.role:Remove()     end
        if d.hpBg     then d.hpBg:Remove()     end
        if d.hpFill   then d.hpFill:Remove()   end
        if d.hpLabel  then d.hpLabel:Remove()  end
        if d.heldItem then d.heldItem:Remove() end
        for _, l in ipairs(d.skel or {}) do l:Remove() end
    end)
    tracked[plr] = nil
end

local function buildSkel(plr)
    local d = tracked[plr]
    if not d then return end
    for _, l in ipairs(d.skel or {}) do
        pcall(function() l:Remove() end)
    end
    d.skel = {}
    d.skelBuilt = false

    local char = plr.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local n = 8
    if hum.RigType == Enum.HumanoidRigType.R15 then n = 10 end

    for i = 1, n do
        local l = Drawing.new("Line")
        l.Color = C3(255,255,255)
        l.Thickness = 2
        l.Visible = false
        d.skel[i] = l
    end
    d.skelBuilt = true
end

local function hideD(d)
    pcall(function()
        for _, l in ipairs(d.box or {}) do l.Visible = false end
        if d.tracer   then d.tracer.Visible   = false end
        if d.name     then d.name.Visible     = false end
        if d.team     then d.team.Visible     = false end
        if d.role     then d.role.Visible     = false end
        if d.hpBg     then d.hpBg.Visible     = false end
        if d.hpFill   then d.hpFill.Visible   = false end
        if d.hpLabel  then d.hpLabel.Visible  = false end
        if d.heldItem then d.heldItem.Visible = false end
        for _, l in ipairs(d.skel or {}) do l.Visible = false end
    end)
end

local function drawSkelR6(d, char)
    local head  = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("Torso")
    if not head or not torso then
        for _, l in ipairs(d.skel) do l.Visible = false end
        return
    end
    local lA = char:FindFirstChild("Left Arm")
    local rA = char:FindFirstChild("Right Arm")
    local lL = char:FindFirstChild("Left Leg")
    local rL = char:FindFirstChild("Right Leg")

    local tc     = torso.CFrame
    local neck   = (tc * CF(0, 1,   0)).Position
    local pelvis = (tc * CF(0,-1,   0)).Position
    local lS     = (tc * CF(-1.5, 1, 0)).Position
    local rS     = (tc * CF( 1.5, 1, 0)).Position
    local lH     = (tc * CF(-0.5,-1, 0)).Position
    local rH     = (tc * CF( 0.5,-1, 0)).Position
    local lHand  = lA and (lA.CFrame * CF(0,-1,0)).Position or lS
    local rHand  = rA and (rA.CFrame * CF(0,-1,0)).Position or rS
    local lFoot  = lL and (lL.CFrame * CF(0,-1,0)).Position or lH
    local rFoot  = rL and (rL.CFrame * CF(0,-1,0)).Position or rH

    local joints = {
        {head.Position, neck},
        {lS, rS},
        {lS, lHand},
        {rS, rHand},
        {neck, pelvis},
        {lH, rH},
        {lH, lFoot},
        {rH, rFoot},
    }
    for i, p in ipairs(joints) do
        local l = d.skel[i]
        if l then
            local a, oA, zA = w2s(p[1])
            local b, oB, zB = w2s(p[2])
            if (oA or oB) and zA > 0 and zB > 0 then
                l.From = a ; l.To = b ; l.Visible = true
            else
                l.Visible = false
            end
        end
    end
end

local function drawSkelR15(d, char)
    local head = char:FindFirstChild("Head")
    local uT   = char:FindFirstChild("UpperTorso")
    local lT   = char:FindFirstChild("LowerTorso")
    local lUA  = char:FindFirstChild("LeftUpperArm")
    local lLA  = char:FindFirstChild("LeftLowerArm")
    local rUA  = char:FindFirstChild("RightUpperArm")
    local rLA  = char:FindFirstChild("RightLowerArm")
    local lUL  = char:FindFirstChild("LeftUpperLeg")
    local lLL  = char:FindFirstChild("LeftLowerLeg")
    local rUL  = char:FindFirstChild("RightUpperLeg")
    local rLL  = char:FindFirstChild("RightLowerLeg")

    if not head or not uT then
        for _, l in ipairs(d.skel) do l.Visible = false end
        return
    end

    local parts = {
        {head, uT}, {uT, lT},
        {uT,  lUA}, {lUA, lLA},
        {uT,  rUA}, {rUA, rLA},
        {lT,  lUL}, {lUL, lLL},
        {lT,  rUL}, {rUL, rLL},
    }
    for i, p in ipairs(parts) do
        local l = d.skel[i]
        if l then
            if p[1] and p[2] and p[1].Parent and p[2].Parent then
                local a, oA, zA = w2s(p[1].Position)
                local b, oB, zB = w2s(p[2].Position)
                if (oA or oB) and zA > 0 and zB > 0 then
                    l.From = a ; l.To = b ; l.Visible = true
                else
                    l.Visible = false
                end
            else
                l.Visible = false
            end
        end
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- MAIN RENDER LOOP
-- ──────────────────────────────────────────────────────────────────────────────
local function getPlayerBox(char, hrp, hum)
    local head = char:FindFirstChild("Head")
    local topWorld = (head and head.Position or (hrp.Position + Vector3.new(0, 2.6, 0))) + Vector3.new(0, 0.65, 0)
    local footOffset = math.max(2.8, (tonumber(hum.HipHeight) or 2) + 2)
    local bottomWorld = hrp.Position - Vector3.new(0, footOffset, 0)

    local top2, onTop, zTop = w2s(topWorld)
    local bottom2, onBottom, zBottom = w2s(bottomWorld)
    if zTop <= 0 or zBottom <= 0 then
        return nil
    end
    if not onTop and not onBottom then
        return nil
    end

    local h = math.abs(bottom2.Y - top2.Y)
    if h < 2 then
        return nil
    end
    local w = math.max(h * 0.52, 2)
    local cx = (top2.X + bottom2.X) * 0.5
    local cy = (top2.Y + bottom2.Y) * 0.5
    return cx, cy, w, h, top2, bottom2
end

RunService.Heartbeat:Connect(function()
    Camera = workspace.CurrentCamera
    for plr, d in pairs(tracked) do
        pcall(function()
            if not alive(plr) then
                hideD(d)
                if not Players:FindFirstChild(plr.Name) then nuke(plr) end
                return
            end

            local char = plr.Character
            local hrp  = char:FindFirstChild("HumanoidRootPart")
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then hideD(d) return end

            local me  = LP.Character
            local myR = me and me:FindFirstChild("HumanoidRootPart")
            if not myR then hideD(d) return end
            local dist = (hrp.Position - myR.Position).Magnitude
            if dist > M.MaxDist then hideD(d) return end

            local cx, cy, w, h, top2 = getPlayerBox(char, hrp, hum)
            if not cx then hideD(d) return end
            local textScale = math.clamp(15 - (dist / 180), 9, 14)
            local compact = h < 14

            -- BOX
            if M.BoxEnabled then
                d.box[1].From = V2(cx-w, cy-h/2) ; d.box[1].To = V2(cx+w, cy-h/2) ; d.box[1].Visible = true
                d.box[2].From = V2(cx-w, cy+h/2) ; d.box[2].To = V2(cx+w, cy+h/2) ; d.box[2].Visible = true
                d.box[3].From = V2(cx-w, cy-h/2) ; d.box[3].To = V2(cx-w, cy+h/2) ; d.box[3].Visible = true
                d.box[4].From = V2(cx+w, cy-h/2) ; d.box[4].To = V2(cx+w, cy+h/2) ; d.box[4].Visible = true
            else
                for i=1,4 do d.box[i].Visible = false end
            end

            -- NAME
            if M.NameEnabled then
                d.name.Size     = textScale
                d.name.Text     = plr.DisplayName or plr.Name
                d.name.Position = V2(cx, top2.Y - textScale - 4)
                d.name.Visible  = true
            else
                d.name.Visible = false
            end

            -- TEAM
            if M.TeamEnabled and not compact then
                local teamName = plr.Team and plr.Team.Name or "No Team"
                d.team.Text  = teamName
                d.team.Color = plr.TeamColor and plr.TeamColor.Color or C3(255,255,255)
                d.team.Size  = math.max(8, textScale - 1)
                if M.BoxEnabled then
                    d.team.Position = V2(cx + w + 8, cy - h/2)
                    d.team.Visible  = true
                else
                    local head = char:FindFirstChild("Head") or hrp
                    local hv, hon, hz = w2s(head.Position + Vector3.new(0,0.45,0))
                    if hon and hz > 0 then
                        d.team.Position = V2(hv.X + 10, hv.Y - 8)
                        d.team.Visible  = true
                    else
                        d.team.Visible = false
                    end
                end
            else
                d.team.Visible = false
            end

            -- ROLE / CLASS
            if M.RoleEnabled and not compact then
                local roleName = getRoleName(plr)
                if roleName then
                    d.role.Text = roleName
                    d.role.Color = C3(255, 255, 255)
                    d.role.Size = math.max(8, textScale - 2)
                    if M.TeamEnabled and d.team.Visible then
                        d.role.Position = V2(d.team.Position.X, d.team.Position.Y + d.team.Size + 1)
                        d.role.Visible = true
                    elseif M.BoxEnabled then
                        d.role.Position = V2(cx + w + 8, cy - h/2 + d.team.Size + 1)
                        d.role.Visible = true
                    else
                        local head = char:FindFirstChild("Head") or hrp
                        local hv, hon, hz = w2s(head.Position + Vector3.new(0, 0.15, 0))
                        if hon and hz > 0 then
                            d.role.Position = V2(hv.X + 10, hv.Y + 6)
                            d.role.Visible = true
                        else
                            d.role.Visible = false
                        end
                    end
                else
                    d.role.Visible = false
                end
            else
                d.role.Visible = false
            end

            -- ──────────────────────────────────────────────────────────────
            -- HEALTH ESP  (fixed for Empire Clash)
            --
            -- Problem was:  hum.Health polled every frame — when DamageService
            --               applies damage server-side, the replicated value
            --               can lag behind and then snap, so the bar would
            --               stutter or not move at all until GC'd.
            --
            -- Fix:          d.cachedHp is updated instantly via HealthChanged
            --               which fires the moment the property replicates.
            --               We just read the cache here — zero polling lag.
            -- ──────────────────────────────────────────────────────────────
            if M.HealthEnabled and not compact then
                -- Ensure we have a live connection (safe to call every frame;
                -- exits early if already connected)
                if not d.hpConns then connectHpCache(plr) end

                local maxHp = d.cachedMaxHp or 100
                local curHp = math.clamp(d.cachedHp or 100, 0, maxHp)
                local frac  = curHp / maxHp  -- 0..1

                local bx = cx - w - 6   -- left of box
                local bt = cy - h/2      -- top
                local bb = cy + h/2      -- bottom

                -- background (full black bar)
                d.hpBg.From    = V2(bx, bb)
                d.hpBg.To      = V2(bx, bt)
                d.hpBg.Visible = true

                -- fill (green at full hp, red at 0)
                d.hpFill.From    = V2(bx, bb)
                d.hpFill.To      = V2(bx, bb - (bb - bt) * frac)
                d.hpFill.Color   = C3(255,0,0):Lerp(C3(0,255,0), frac)
                d.hpFill.Visible = true

                -- numeric label top-left of bar (e.g. "87")
                d.hpLabel.Text     = tostring(math.floor(curHp))
                d.hpLabel.Position = V2(bx - 12 - (math.max(0, #d.hpLabel.Text-2) * 3), bt - 4)
                d.hpLabel.Size     = math.max(8, textScale - 2)
                d.hpLabel.Center   = false
                d.hpLabel.Visible  = true
            else
                d.hpBg.Visible    = false
                d.hpFill.Visible  = false
                d.hpLabel.Visible = false
            end

            -- TRACERS
            if M.TracersEnabled then
                local ox = Camera.ViewportSize.X / 2
                local oy = Camera.ViewportSize.Y
                d.tracer.From    = V2(ox, oy)
                d.tracer.To      = V2(cx, cy + h/2)
                d.tracer.Visible = true
            else
                d.tracer.Visible = false
            end

            -- SKELETON
            if M.SkeletonEnabled then
                if not d.skelBuilt then buildSkel(plr) end
                if hum.RigType == Enum.HumanoidRigType.R15 then
                    drawSkelR15(d, char)
                else
                    drawSkelR6(d, char)
                end
            else
                for _, l in ipairs(d.skel or {}) do
                    pcall(function() l.Visible = false end)
                end
            end

            -- HELD ITEM
            if M.HeldItemEnabled and h >= 16 then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool then
                    d.heldItem.Size     = math.max(8, textScale - 1)
                    d.heldItem.Text     = tool.Name
                    d.heldItem.Position = V2(cx, cy + h/2 + 4)
                    d.heldItem.Visible  = true
                else
                    d.heldItem.Visible = false
                end
            else
                d.heldItem.Visible = false
            end
        end)
    end

    local resourceAnyEnabled = false
    for _, enabled in pairs(M.ResourceEnabledByName) do
        if enabled then
            resourceAnyEnabled = true
            break
        end
    end

    local oreAnyEnabled = false
    for _, enabled in pairs(M.OreEnabledByName) do
        if enabled then
            oreAnyEnabled = true
            break
        end
    end

    local animalAnyEnabled = M.AnimalEnabled and true or false

    if not resourceAnyEnabled and not oreAnyEnabled and not animalAnyEnabled then
        for _, data in pairs(resourceTracked) do
            hideResource(data)
        end
        for _, data in pairs(oreTracked) do
            hideOre(data)
        end
        for _, data in pairs(animalTracked) do
            hideAnimal(data)
        end
        return
    end

    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        for _, data in pairs(resourceTracked) do
            hideResource(data)
        end
        for _, data in pairs(oreTracked) do
            hideOre(data)
        end
        for _, data in pairs(animalTracked) do
            hideAnimal(data)
        end
        return
    end

    if resourceAnyEnabled then
        for node, data in pairs(resourceTracked) do
            pcall(function()
                if not node.Parent or not CollectionService:HasTag(node, "ResourceNode") then
                    untrackResource(node)
                    return
                end

                local resourceName = data.resourceName or resolveResourceType(node)
                if not resourceName then
                    hideResource(data)
                    return
                end
                data.resourceName = resourceName

                if not M.ResourceEnabledByName[resourceName] then
                    hideResource(data)
                    return
                end

                if node:GetAttribute("Gatherable") == false then
                    hideResource(data)
                    return
                end

                local pos = nodePos(node)
                if not pos then
                    hideResource(data)
                    return
                end

                local dist = (pos - myRoot.Position).Magnitude
                if dist > M.MaxDist then
                    hideResource(data)
                    return
                end

                local screen, on, z = w2s(pos + Vector3.new(0, 1.4, 0))
                if not on or z <= 0 then
                    hideResource(data)
                    return
                end

                data.text.Text = resourceName .. " [" .. tostring(math.floor(dist + 0.5)) .. "s]"
                data.text.Position = screen
                data.text.Color = resourceColors[resourceName] or C3(255, 255, 255)
                data.text.Visible = true
            end)
        end
    else
        for _, data in pairs(resourceTracked) do
            hideResource(data)
        end
    end

    if oreAnyEnabled then
        for node, data in pairs(oreTracked) do
            pcall(function()
                if not node.Parent or not CollectionService:HasTag(node, "ResourceNode") then
                    untrackOre(node)
                    return
                end

                local oreName = data.oreName or resolveOreType(node)
                if not oreName then
                    hideOre(data)
                    return
                end
                data.oreName = oreName

                if not M.OreEnabledByName[oreName] then
                    hideOre(data)
                    return
                end

                if node:GetAttribute("Gatherable") == false then
                    hideOre(data)
                    return
                end

                local pos = nodePos(node)
                if not pos then
                    hideOre(data)
                    return
                end

                local dist = (pos - myRoot.Position).Magnitude
                if dist > M.MaxDist then
                    hideOre(data)
                    return
                end

                local screen, on, z = w2s(pos + Vector3.new(0, 1.4, 0))
                if not on or z <= 0 then
                    hideOre(data)
                    return
                end

                data.text.Text = oreName .. " [" .. tostring(math.floor(dist + 0.5)) .. "s]"
                data.text.Position = screen
                data.text.Color = oreColors[oreName] or C3(255, 255, 255)
                data.text.Visible = true
            end)
        end
    else
        for _, data in pairs(oreTracked) do
            hideOre(data)
        end
    end

    if animalAnyEnabled then
        for rootPart, data in pairs(animalTracked) do
            pcall(function()
                if not rootPart.Parent or not CollectionService:HasTag(rootPart, "AnimalRootPart") then
                    untrackAnimal(rootPart)
                    return
                end

                local model = rootPart.Parent
                if not model or model.Name == "HumanoidModel" then
                    hideAnimal(data)
                    return
                end

                local hum = model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health <= 0 then
                    hideAnimal(data)
                    return
                end

                local animalName = data.animalName or resolveAnimalName(rootPart)
                if not animalName then
                    hideAnimal(data)
                    return
                end
                data.animalName = animalName

                local pos = rootPart.Position
                local dist = (pos - myRoot.Position).Magnitude
                if dist > M.MaxDist then
                    hideAnimal(data)
                    return
                end

                local screen, on, z = w2s(pos + Vector3.new(0, 1.6, 0))
                if not on or z <= 0 then
                    hideAnimal(data)
                    return
                end

                data.text.Text = animalName .. " [" .. tostring(math.floor(dist + 0.5)) .. "s]"
                data.text.Position = screen
                data.text.Color = animalColors[animalName] or C3(255, 255, 255)
                data.text.Visible = true
            end)
        end
    else
        for _, data in pairs(animalTracked) do
            hideAnimal(data)
        end
    end
end)

-- ──────────────────────────────────────────────────────────────────────────────
-- PLAYER TRACKING
-- ──────────────────────────────────────────────────────────────────────────────
local function onPlr(plr)
    if plr == LP then return end
    pcall(function()
        make(plr)
        -- Reconnect HP cache AND rebuild skeleton on every respawn
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)  -- short wait for Humanoid to be parented
            pcall(connectHpCache, plr)
            pcall(buildSkel, plr)
        end)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do pcall(onPlr, p) end
Players.PlayerAdded:Connect(function(p) pcall(onPlr, p) end)
Players.PlayerRemoving:Connect(function(p) pcall(nuke, p) end)

-- ──────────────────────────────────────────────────────────────────────────────
-- PUBLIC API  (unchanged surface — Empireclash.lua calls these)
-- ──────────────────────────────────────────────────────────────────────────────
local API = {}
function API:Init() end
function API:SetBoxEsp(s)      M.BoxEnabled      = s end
function API:SetNameEsp(s)     M.NameEnabled     = s end
function API:SetHealthEsp(s)   M.HealthEnabled   = s end
function API:SetTracers(s)     M.TracersEnabled  = s end
function API:SetTeamEsp(s)     M.TeamEnabled     = s end
function API:SetRoleEsp(s)     M.RoleEnabled     = s end
function API:SetSkeletonEsp(s)
    M.SkeletonEnabled = s
    if s then
        for p in pairs(tracked) do pcall(buildSkel, p) end
    end
end
function API:SetHeldItemEsp(s) M.HeldItemEnabled = s end
function API:SetAnimalEsp(s)   M.AnimalEnabled   = s end
function API:SetAnimalsEsp(s)  M.AnimalEnabled   = s end
function API:SetMaxDist(v)     M.MaxDist         = v end
function API:GetResourceTypes()
    local out = {}
    for _, resourceName in ipairs(resourceTypes) do
        table.insert(out, resourceName)
    end
    return out
end
function API:SetResourceTypeEsp(name, state)
    if type(name) ~= "string" or name == "" then return end
    if M.ResourceEnabledByName[name] == nil then
        resourceAddType(name)
        table.sort(resourceTypes)
    end
    M.ResourceEnabledByName[name] = state and true or false
end
function API:SetAllResourcesEsp(state)
    local enabled = state and true or false
    for resourceName in pairs(M.ResourceEnabledByName) do
        M.ResourceEnabledByName[resourceName] = enabled
    end
end
function API:SetResourceEsp(state)
    self:SetAllResourcesEsp(state)
end
function API:GetOreTypes()
    local out = {}
    for _, oreName in ipairs(oreTypes) do
        table.insert(out, oreName)
    end
    return out
end
function API:SetOreTypeEsp(name, state)
    if type(name) ~= "string" or name == "" then return end
    if M.OreEnabledByName[name] == nil then
        oreAddType(name)
        table.sort(oreTypes)
    end
    M.OreEnabledByName[name] = state and true or false
end
function API:SetAllOresEsp(state)
    local enabled = state and true or false
    for oreName in pairs(M.OreEnabledByName) do
        M.OreEnabledByName[oreName] = enabled
    end
end
function API:SetOreEsp(state)
    self:SetAllOresEsp(state)
end
return API
