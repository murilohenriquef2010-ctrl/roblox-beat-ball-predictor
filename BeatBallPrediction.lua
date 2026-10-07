local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local BALL_NAMES = {
    "Ball",
    "ball",
    "SoccerBall",
    "Football",
    "FootballBall",
    "KickBall",
    "BeachBall",
    "BallModel"
}

local lineFolder = Instance.new("Folder")
lineFolder.Name = "BeatBallPrediction"
lineFolder.Parent = Workspace

local function findBall()
    local root = Workspace

    for _, name in ipairs(BALL_NAMES) do
        local found = root:FindFirstChild(name)
        if found then
            return found
        end
    end

    for _, model in ipairs(root:GetDescendants()) do
        if model:IsA("BasePart") then
            local lower = string.lower(model.Name)
            if lower:find("ball") or lower:find("bola") then
                return model
            end
        end
    end

    return nil
end

local function clearPrediction()
    for _, child in ipairs(lineFolder:GetChildren()) do
        child:Destroy()
    end
end

local function makeLine(startPos, endPos, color)
    local distance = (startPos - endPos).Magnitude
    if distance <= 0.1 then
        return nil
    end

    local part = Instance.new("Part")
    part.Name = "PredictionLine"
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.25
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Size = Vector3.new(0.35, 0.35, distance)
    part.CFrame = CFrame.new((startPos + endPos) / 2, endPos)
    part.Parent = lineFolder

    local glow = Instance.new("SelectionBox")
    glow.Adornee = part
    glow.Color3 = color
    glow.LineThickness = 0.06
    glow.Transparency = 0.25
    glow.Parent = part

    return part
end

local function makeTarget(pos, color)
    local target = Instance.new("Part")
    target.Name = "PredictionTarget"
    target.Anchored = true
    target.CanCollide = false
    target.Material = Enum.Material.Neon
    target.Color = color
    target.Shape = Enum.PartType.Cylinder
    target.Size = Vector3.new(0.6, 0.2, 0.6)
    target.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    target.Parent = lineFolder

    return target
end

local function getGroundY(pos)
    local ray = Workspace:Raycast(pos + Vector3.new(0, 20, 0), Vector3.new(0, -100, 0), RaycastParams.new())
    if ray then
        return ray.Position.Y + 0.25
    end
    return pos.Y
end

local function predictStopPoint(startPos, initialVelocity)
    local pos = startPos
    local vel = initialVelocity
    local dt = 1/60
    local maxTime = 15
    local groundY = getGroundY(pos)

    for i = 1, 120 do
        vel = vel * Vector3.new(0.996, 0.996, 0.996)
        vel = vel + Vector3.new(0, -Workspace.Gravity * dt * 0.7, 0)
        pos = pos + vel * dt

        local currentGround = getGroundY(pos)
        if pos.Y <= currentGround + 0.35 then
            pos = Vector3.new(pos.X, currentGround + 0.35, pos.Z)
            return pos
        end

        if i > 90 and pos.Y < groundY + 3 then
            break
        end
    end

    return pos
end

local lastBall = nil
local lastPrediction = nil

local function updatePrediction()
    local ball = findBall()
    if not ball then
        clearPrediction()
        lastBall = nil
        return
    end

    if lastBall ~= ball then
        lastBall = ball
    end

    local part = ball
    if not part:IsA("BasePart") then
        return
    end

    local v = part.AssemblyLinearVelocity
    local speed = v.Magnitude

    if speed < 1 then
        clearPrediction()
        return
    end

    local startPos = part.Position
    local endPos = predictStopPoint(startPos, v)

    clearPrediction()

    local line = makeLine(startPos, endPos, Color3.fromRGB(255, 86, 86))
    local target = makeTarget(endPos, Color3.fromRGB(60, 200, 255))

    if line then
        line.Transparency = 0.55
        line.Material = Enum.Material.Neon
    end

    if target then
        target.Size = Vector3.new(0.9, 0.2, 0.9)
        target.Transparency = 0.4
    end
end

RunService.RenderStepped:Connect(updatePrediction)

print("[BeatBallPrediction] Script carregado. Linha de previsão ativa.")
