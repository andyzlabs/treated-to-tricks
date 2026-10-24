-- Run once in Slap Battles to teleport directly into Halloween 26 and start.
-- Stop with: getgenv().TreatedToTricks:Stop()
local SOURCE = [====[
-- Halloween 26 / Treated to Tricks. Run in the main game or the event.
-- Stop with: getgenv().TreatedToTricks:Stop()
if not game:IsLoaded() then game.Loaded:Wait() end
local env = getgenv()
if env.TreatedToTricks and type(env.TreatedToTricks.Stop) == "function" then
    env.TreatedToTricks:Stop()
end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
while not Players.LocalPlayer do task.wait() end
local player = Players.LocalPlayer
local bot = { Running = true, Status = "Starting...", Connections = {} }
env.TreatedToTricks = bot

-- Only a notification at the top; no menu or buttons.
local gui = Instance.new("ScreenGui")
gui.Name = "TreatedToTricksStatus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10000
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 10)
banner.Size = UDim2.new(0.85, 0, 0, 48)
banner.BackgroundColor3 = Color3.fromRGB(28, 24, 32)
banner.BackgroundTransparency = 0.15
banner.TextColor3 = Color3.fromRGB(255, 217, 137)
banner.Font = Enum.Font.GothamMedium
banner.TextSize = 16
banner.TextWrapped = true
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = banner
local width = Instance.new("UISizeConstraint")
width.MaxSize = Vector2.new(740, 48)
width.Parent = banner

local function status(text)
    bot.Status = text
    banner.Text = "Treated to Tricks  |  " .. text
end

local hoverPosition
function bot:Stop()
    self.Running = false
    hoverPosition = nil
    for _, connection in self.Connections do
        connection:Disconnect()
    end
    if self.Thread and coroutine.running() ~= self.Thread then
        pcall(task.cancel, self.Thread)
    end
    gui:Destroy()
end

if game.PlaceId ~= 82340649038345 then
    if game.PlaceId ~= 6403373529 then
        status("Run this in Slap Battles or Halloween 26.")
        bot.Running = false
        return
    end
    local queue = queue_on_teleport or queueonteleport
        or (type(syn) == "table" and syn.queue_on_teleport)
    if type(queue) ~= "function" then
        status("This executor needs queue_on_teleport to resume in Halloween 26.")
        bot.Running = false
        return
    end
    local ok, err = pcall(queue, EVENT_SOURCE)
    if not ok then
        status("Could not queue the event script: " .. tostring(err):sub(1, 90))
        bot.Running = false
        return
    end
    local teleports = game:GetService("TeleportService")
    local failed = false
    table.insert(bot.Connections, teleports.TeleportInitFailed:Connect(function(who, _, reason, placeId)
        if who == player and placeId == 82340649038345 then
            failed = true
            status("Teleport failed: " .. tostring(reason):sub(1, 90) .. ". Run again to retry.")
            bot.Running = false
        end
    end))
    bot.Thread = task.spawn(function()
        status("Teleporting directly to Halloween 26...")
        local started, problem = pcall(teleports.Teleport, teleports, 82340649038345, player)
        if not started and not failed then
            status("Teleport failed: " .. tostring(problem):sub(1, 90) .. ". Run again to retry.")
            bot.Running = false
        end
    end)
    return
end
if type(fireproximityprompt) ~= "function" then
    status("This executor needs fireproximityprompt support.")
    bot.Running = false
    return
end

local Common = require(RS.Modules.GameCommon)
local dialogue = RS.Modules.Common.DialogueServer.Remotes
local doorCooldown = setmetatable({}, { __mode = "k" })
local lastHit = setmetatable({}, { __mode = "k" })
local activeDoor
local lastDialogue = 0
local lastTalk = 0
local lastSwing = 0

local function character()
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if not c or not h or h.Health <= 0 or not root or player:GetAttribute("HasDied") then
        return nil
    end
    return c, h, root
end

local function move(position, lookAt)
    local c, _, root = character()
    if not c then return false end
    hoverPosition = position
    c:PivotTo(lookAt and CFrame.lookAt(position, lookAt) or CFrame.new(position))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    return true
end

-- Stay above attacking candy corns instead of falling into their hitboxes.
table.insert(bot.Connections, RunService.Heartbeat:Connect(function()
    local _, _, root = character()
    if bot.Running and hoverPosition and root and not root.Anchored then
        root.CFrame = CFrame.new(hoverPosition) * root.CFrame.Rotation
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end))

local function promptPosition(prompt)
    local p = prompt.Parent
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("BasePart") or p:IsA("Model") then return p:GetPivot().Position end
end

local function interact(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end
    local position = promptPosition(prompt)
    if not position or not move(position + Vector3.new(0, 7, 2), position) then return false end
    task.wait(0.15)
    if not bot.Running or not prompt.Parent or not prompt.Enabled then return false end
    fireproximityprompt(prompt, prompt.HoldDuration + 0.1)
    task.wait(0.2)
    return true
end

local function dropPrompt()
    local folder = workspace:FindFirstChild("DropZone")
    local drop = folder and folder:FindFirstChild("DropZone")
    return drop and drop:FindFirstChildOfClass("ProximityPrompt")
end

local function talkPrompt()
    local folder = workspace:FindFirstChild("DropZone")
    local outer = folder and folder:FindFirstChild("NPC")
    local npc = outer and outer:FindFirstChild("NPC")
    return npc and npc:FindFirstChildOfClass("ProximityPrompt")
end

local function cornifierPosition()
    local p = talkPrompt()
    if p then return promptPosition(p) end
    local folder = workspace:FindFirstChild("DropZone")
    local drop = folder and folder:FindFirstChild("DropZone")
    return drop and drop:GetPivot().Position
end

local function feedPrompt()
    for _, prompt in workspace:QueryDescendants("ProximityPrompt[Enabled = true]") do
        local action = prompt.ActionText:lower()
        if action:find("feed", 1, true) or action:find("give", 1, true) then
            return prompt
        end
    end
    return dropPrompt()
end

-- Match the game's actual response indices; reject an anomalous resident.
table.insert(bot.Connections, dialogue.ShowDialogue.OnClientEvent:Connect(function(_, title, _, _, options)
    lastDialogue = os.clock()
    task.wait(0.3)
    if not bot.Running then return end
    local answer = 0
    if type(options) == "table" then
        for index, text in options do
            if type(text) == "string" then
                local lower = text:lower()
                if lower:find("accept", 1, true) then
                    if activeDoor and activeDoor:GetAttribute("IsAnomaly") == false then
                        answer = index
                    end
                elseif lower:find("no thanks", 1, true) and answer == 0 then
                    answer = index
                end
            end
        end
    end
    dialogue.ResondToDialogue:FireServer(answer)
end))

local function equip()
    local c, h = character()
    if not c then return end
    local tool = c:FindFirstChild("Lantern")
    if not tool then
        tool = player.Backpack:FindFirstChild("Lantern")
        if tool then h:EquipTool(tool) end
    end
    return tool
end

local function enemy(around, waveOnly)
    local best, distance
    for _, tag in (waveOnly and { "WaveMinion" } or { "PatrolNPC", "WaveMinion" }) do
        for _, model in Tags:GetTagged(tag) do
            if model:IsDescendantOf(workspace) and not model:GetAttribute("IsDead") then
                local hit = model:FindFirstChild("CandyCorn")
                local h = model:FindFirstChildOfClass("Humanoid")
                if hit and h and h.Health > 0 and os.clock() - (lastHit[model] or 0) >= 0.36 then
                    local d = (hit.Position - around).Magnitude
                    if not distance or d < distance then
                        best, distance = model, d
                    end
                end
            end
        end
    end
    return best
end

local function attack(model)
    local hit = model:FindFirstChild("CandyCorn")
    local tool = equip()
    local network = tool and tool:FindFirstChild("Network")
    if not hit or not network then return end
    move(hit.Position + Vector3.new(0, 10, 0), hit.Position)
    task.wait(0.08)
    if not bot.Running or not hit:IsDescendantOf(workspace) then return end
    if os.clock() - lastSwing >= 0.52 then
        tool:Activate()
        lastSwing = os.clock()
    end
    network:FireServer("Hit", hit)
    lastHit[model] = os.clock()
end

local function safeDoor(around)
    local best, distance
    for _, door in Tags:GetTagged("Door") do
        if door:IsDescendantOf(workspace) and door:GetAttribute("Enabled") == true
            and door:GetAttribute("IsAnomaly") == false and not door:GetAttribute("WasCollected")
            and not door:GetAttribute("Open") and os.clock() >= (doorCooldown[door] or 0) then
            local prompt = door:FindFirstChild("ProximityPrompt", true)
            if prompt and prompt.Enabled then
                local d = (door:GetPivot().Position - around).Magnitude
                if not distance or d < distance then best, distance = door, d end
            end
        end
    end
    return best
end

local function collectHouse(door)
    activeDoor = door
    doorCooldown[door] = os.clock() + 20
    if interact(door:FindFirstChild("ProximityPrompt", true)) then
        local deadline = os.clock() + 9
        repeat
            task.wait(0.15)
        until not bot.Running or not character() or not door.Parent
            or door:GetAttribute("WasCollected") or os.clock() >= deadline
    end
    activeDoor = nil
end

local function collectObject(object)
    for _, prompt in object:QueryDescendants("ProximityPrompt[Enabled = true]") do
        interact(prompt)
        return
    end
    local parts = object:IsA("BasePart") and { object } or object:QueryDescendants("BasePart")
    for _, part in parts do
        if not bot.Running or not part.Parent then break end
        local _, _, root = character()
        if not root then return end
        move(part.Position)
        if part.CanTouch and type(firetouchinterest) == "function" then
            firetouchinterest(root, part, 0)
            task.wait(0.05)
            if root.Parent and part.Parent then firetouchinterest(root, part, 1) end
        end
    end
    task.wait(0.25)
end

bot.Thread = task.spawn(function()
    status("Starting automatic candy collection...")
    while bot.Running do
        local ok, err = pcall(function()
            local c, _, root = character()
            if not c then
                hoverPosition = nil
                if #Common.getAlivePlayers() == 0 then
                    status("All players are down. Rejoin Halloween 26 and run the script again.")
                else
                    status("Waiting to revive at the next round...")
                end
                return
            end
            equip()
            local round = Common.getRound()
            local stage = workspace:GetAttribute("EndSequenceStage")
            local center = cornifierPosition() or root.Position
            if stage == "Complete" then
                status("Event complete; waiting for the return teleport...")
                return
            end
            local gloves = workspace:QueryDescendants("#RevenantGlove")
            if #gloves > 0 and (stage == "Glove" or stage == "Revenant") then
                status("Touching the Revenant glove to claim the badge...")
                collectObject(gloves[1])
                return
            end
            if Common.isWaveStarted() or Common.isFinalEating() then
                local seconds = math.max(0, math.ceil(Common.getWaveEnd() - workspace:GetServerTimeNow()))
                status(("Defending Cornifier%s | %ds remaining"):format(Common.isFinalEating() and " (final wave)" or "", seconds))
                local target = enemy(center, true)
                if target then attack(target) else move(center + Vector3.new(0, 14, 0)) end
                return
            end
            if Common.isFinalStarted() then
                if not Common.isSoulCandyCollected() then
                    status("Finding and collecting the final candy corn...")
                    local candy = workspace:QueryDescendants("#SoulCandy")
                    if candy[1] then collectObject(candy[1]) end
                else
                    status("Bringing the final candy to Cornifier...")
                    local prompt = feedPrompt()
                    if prompt and prompt.Enabled then interact(prompt)
                    else
                        local talk = talkPrompt()
                        if talk and talk.Enabled and os.clock() - lastTalk > 5 then
                            lastTalk = os.clock()
                            interact(talk)
                        else move(center + Vector3.new(0, 5, 0)) end
                    end
                end
                return
            end
            if stage == "Revenant" or stage == "Glove" then
                status("Waiting for the Revenant glove...")
                return
            end
            if not Common.isGameStarted() then
                status("Talking to Count Cornifier...")
                if os.clock() - lastTalk > 8 then
                    lastTalk = os.clock()
                    interact(talkPrompt())
                end
                return
            end
            local talk = talkPrompt()
            if talk and talk.Enabled and talk.Parent:GetAttribute("ActiveNotification") == true
                and not workspace:GetAttribute("DialogueOpen") and os.clock() - lastTalk > 8 then
                status("Talking to Count Cornifier...")
                lastTalk = os.clock()
                interact(talk)
                return
            end
            if workspace:GetAttribute("DialogueOpen") then
                status("Advancing Cornifier's dialogue...")
                if os.clock() - lastDialogue > 2 then
                    dialogue.ResondToDialogue:FireServer(0)
                    lastDialogue = os.clock()
                end
                return
            end
            local bag = Common.getPlayerCandy(player)
            local quota = Common.getRoundCandyQuota(round)
            local deposited = Common.getDepositedCandy()
            if deposited >= quota then
                status(("Round %d complete | Voting to start defense..."):format(round))
                interact(dropPrompt())
            elseif bag >= Common.getCandyBagSize() or bag >= quota - deposited then
                status(("Round %d | Depositing %d candy..."):format(round, bag))
                interact(dropPrompt())
            elseif Common.isRoundStarted() then
                local door = safeDoor(root.Position)
                if door then
                    status(("Round %d | Trick-or-treating at a safe house | Bag %d/%d"):format(round, bag, Common.getCandyBagSize()))
                    collectHouse(door)
                else
                    status(("Round %d | Attacking candy corns | Bag %d/%d | Zone %d/%d"):format(round, bag, Common.getCandyBagSize(), deposited, quota))
                    local target = enemy(root.Position, false)
                    if target then attack(target)
                    elseif bag > 0 then interact(dropPrompt()) end
                end
            else
                status("Waiting for the next round...")
            end
        end)
        if not ok then
            bot.LastError = tostring(err)
            status("Retrying: " .. tostring(err):sub(1, 110))
            task.wait(1)
        end
        task.wait(0.14)
    end
end)

]====]
local entry, err = loadstring("local EVENT_SOURCE = ...\n" .. SOURCE, "TreatedToTricks")
assert(entry, err)
entry("local EVENT_SOURCE = nil\n" .. SOURCE)
