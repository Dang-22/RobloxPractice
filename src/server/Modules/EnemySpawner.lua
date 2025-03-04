local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

-- Constructor for EnemySpawner.
-- The config table should include:
--    enemyTemplate: a reference to an enemy model in ServerStorage.
--    spawnPoints: an array of spawn location BaseParts (each with its own PatrolPoints folder and a MaxEnemies IntValue).
--    defaultMaxEnemies (optional): default max enemy count if a spawn point doesn’t have a MaxEnemies value.
function EnemySpawner.new(config)
    local self = setmetatable({}, EnemySpawner)
    self.config = config or {}
    self.spawnPoints = self.config.spawnPoints or {}
    self.enemyTemplate = self.config.enemyTemplate
    self.defaultMaxEnemies = self.config.defaultMaxEnemies or 3
    return self
end

-- Creates or gets a folder to hold enemy clones.
function EnemySpawner:InitEnemyFolder()
    local enemyFolder = game.Workspace:FindFirstChild("Enemies")
    if not enemyFolder then
        enemyFolder = Instance.new("Folder")
        enemyFolder.Name = "Enemies"
        enemyFolder.Parent = game.Workspace
    end
    self.enemyFolder = enemyFolder
end

-- Counts how many enemies spawned from the given spawn point exist.
function EnemySpawner:CountEnemiesForSpawnPoint(spawnPoint)
    local count = 0
    for _, enemy in ipairs(self.enemyFolder:GetChildren()) do
        if enemy:IsA("Model") then
            local spAttr = enemy:GetAttribute("SpawnPoint")
            if spAttr and spAttr == spawnPoint.Name then
                count = count + 1
            end
        end
    end
    return count
end

-- Retrieves the maximum enemy count from a spawn point.
function EnemySpawner:GetMaxEnemiesForSpawnPoint(spawnPoint)
    local maxEnemiesValue = spawnPoint:FindFirstChild("MaxEnemies")
    if maxEnemiesValue and maxEnemiesValue:IsA("IntValue") then
        return maxEnemiesValue.Value
    end
    return self.defaultMaxEnemies
end

-- Spawns one enemy at the given spawn point.
function EnemySpawner:SpawnEnemyAtSpawnPoint(spawnPoint)
    local enemyClone = self.enemyTemplate:Clone()
    enemyClone.Parent = self.enemyFolder
    enemyClone:MoveTo(spawnPoint.Position)
    
    -- Ensure the enemy model has its PrimaryPart set.
    if not enemyClone.PrimaryPart and enemyClone:FindFirstChild("HumanoidRootPart") then
        enemyClone.PrimaryPart = enemyClone.HumanoidRootPart
    end

    -- Mark the enemy with its spawn point ID using an attribute.
    enemyClone:SetAttribute("SpawnPoint", spawnPoint.Name)
    
    -- Gather patrol points from the spawn point’s PatrolPoints folder.
    local patrolPoints = {}
    local patrolFolder = spawnPoint:FindFirstChild("PatrolPoints")
    if patrolFolder then
        for _, point in ipairs(patrolFolder:GetChildren()) do
            if point:IsA("Part") then
                table.insert(patrolPoints, point.Position)
            end
        end
    else
        warn("No PatrolPoints folder found for spawn point:", spawnPoint.Name)
    end

    -- Start the enemy's AI with its patrol waypoints.
    local EnemyAI = require(game.ServerScriptService.Server.Modules.EnemyAI)
    EnemyAI.StartAI(enemyClone, {
        detectionRadius = 20,
        waypoints = patrolPoints
    })
    
    -- Attach a touch event to the enemy's PrimaryPart so that when the enemy touches a player,
    -- it turns red and is destroyed.
    if enemyClone.PrimaryPart then
        enemyClone.PrimaryPart.Touched:Connect(function(hit)
            local Players = game:GetService("Players")
            local character = hit.Parent
            local player = Players:GetPlayerFromCharacter(character)
            if player then
                -- Change all BaseParts in the enemy to red.
                for _, part in ipairs(enemyClone:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.BrickColor = BrickColor.new("Bright red")
                    end
                end
                -- Destroy the enemy.
                enemyClone:Destroy()
            end
        end)
    end
end

-- Continuously checks each spawn point. If the number of enemies spawned from that point is below
-- the defined maximum, new enemies are spawned to replenish the count.
function EnemySpawner:StartSpawning()
    self:InitEnemyFolder()
    spawn(function()
        while true do
            for _, spawnPoint in ipairs(self.spawnPoints) do
                if spawnPoint:IsA("Part") then
                    local maxEnemies = self:GetMaxEnemiesForSpawnPoint(spawnPoint)
                    local currentCount = self:CountEnemiesForSpawnPoint(spawnPoint)
                    if currentCount < maxEnemies then
                        local missing = maxEnemies - currentCount
                        for i = 1, missing do
                            self:SpawnEnemyAtSpawnPoint(spawnPoint)
                        end
                    end
                end
            end
            wait(1) -- Check every second (adjust as needed)
        end
    end)
end

return EnemySpawner