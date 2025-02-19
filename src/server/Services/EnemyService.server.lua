local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local EnemySpawner = require(game:GetService("ServerScriptService").Server.Modules.EnemySpawner)

local EnemyService = Knit.CreateService {
    Name = "EnemyService",
    Client = {} -- You can add client functions here if needed.
}

function EnemyService:KnitInit()
    -- Configure enemy spawning.
    local ServerStorage = game:GetService("ServerStorage")
    local Workspace = game:GetService("Workspace")
    local config = {}
    
    -- Retrieve the enemy template.
    config.enemyTemplate = ServerStorage:WaitForChild("EnemyTemplate")
    
    -- Gather spawn points from a folder in Workspace.
    local spawnPointsFolder = Workspace:WaitForChild("SpawnPoints")
    config.spawnPoints = {}
    for _, sp in ipairs(spawnPointsFolder:GetChildren()) do
        if sp:IsA("BasePart") then
            table.insert(config.spawnPoints, sp)
        end
    end
    
    -- Set enemy spawn settings.
    config.enemiesPerWave = 3
    config.waveInterval = 15
    
    -- Configure waypoints (optional).
    config.waypoints = {}
    local waypointsFolder = Workspace:FindFirstChild("Waypoints")
    if waypointsFolder then
        for _, wp in ipairs(waypointsFolder:GetChildren()) do
            if wp:IsA("BasePart") then
                table.insert(config.waypoints, wp.Position)
            end
        end
    else
        -- Fallback: use spawn points as waypoints.
        for _, sp in ipairs(config.spawnPoints) do
            table.insert(config.waypoints, sp.Position)
        end
    end
    
    self.Spawner = EnemySpawner.new(config)
end

function EnemyService:KnitStart()
    self.Spawner:StartSpawning()
    print("Enemy Service has started spawning enemy waves!")
end

return EnemyService