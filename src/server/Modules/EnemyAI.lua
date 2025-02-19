local EnemyAI = {}
EnemyAI.__index = EnemyAI

-- Constructor for EnemyAI instance.
function EnemyAI.new(enemyInstance, options)
    local self = setmetatable({}, EnemyAI)
    self.enemy = enemyInstance
    self.detectionRadius = (options and options.detectionRadius) or 20
    self.waypoints = (options and options.waypoints) or {}
    self.currentWaypointIndex = 1
    self.isChasing = false
    self.active = true
    self.targetPlayer = nil
    return self
end

-- Main AI loop that runs continuously.
function EnemyAI:Run()
    while self.active do
        wait(0.5)  -- Small delay to reduce performance impact.

        self:DetectPlayer()

        if self.isChasing then
            self:ChasePlayer()
        else
            self:FollowWaypoints()
        end
    end
end

-- Checks for nearby players and sets a target if found.
function EnemyAI:DetectPlayer()
    local players = game:GetService("Players"):GetPlayers()
    local nearestPlayer = nil
    local nearestDist = self.detectionRadius

    for _, player in ipairs(players) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local distance = (self.enemy.PrimaryPart.Position - character.HumanoidRootPart.Position).Magnitude
            if distance <= nearestDist then
                nearestDist = distance
                nearestPlayer = player
            end
        end
    end

    if nearestPlayer then
        self.targetPlayer = nearestPlayer
        self.isChasing = true
    else
        self.targetPlayer = nil
        self.isChasing = false
    end
end

-- Chases the detected player.
function EnemyAI:ChasePlayer()
    local character = self.targetPlayer and self.targetPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local targetPos = character.HumanoidRootPart.Position
        self:MoveToTarget(targetPos)
    end
end

-- Follows a predetermined loop of waypoints.
function EnemyAI:FollowWaypoints()
    if #self.waypoints > 0 then
        local waypoint = self.waypoints[self.currentWaypointIndex]
        if waypoint then
            self:MoveToTarget(waypoint)
            if (self.enemy.PrimaryPart.Position - waypoint).Magnitude < 2 then
                self.currentWaypointIndex = (self.currentWaypointIndex % #self.waypoints) + 1
            end
        end
    end
end

-- Moves the enemy toward the target position using its Humanoid.
function EnemyAI:MoveToTarget(targetPos)
    local humanoid = self.enemy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:MoveTo(targetPos)
    end
end

-- Stops the AI loop.
function EnemyAI:Destroy()
    self.active = false
end

-- Public method to initialize and start the AI for an enemy instance.
function EnemyAI.StartAI(enemyInstance, options)
    -- Ensure the enemy model has its PrimaryPart set (assumes a "HumanoidRootPart" exists).
    if not enemyInstance.PrimaryPart and enemyInstance:FindFirstChild("HumanoidRootPart") then
        enemyInstance.PrimaryPart = enemyInstance.HumanoidRootPart
    end

    local instance = EnemyAI.new(enemyInstance, options)
    spawn(function()
        instance:Run()
    end)
    return instance
end

return EnemyAI