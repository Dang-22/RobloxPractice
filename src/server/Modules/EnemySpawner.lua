local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

-- Constructor for EnemySpawner.
-- The config table should include:
--    enemyTemplate: a reference to an enemy model in ServerStorage.
--    spawnPoints: an array of spawn location BaseParts.
--    enemiesPerWave: number of enemies per wave.
--    waveInterval: time (in seconds) between waves.
--    waypoints: an array of Vector3 positions for enemy navigation.
function EnemySpawner.new(config)
    local self = setmetatable({}, EnemySpawner)
    self.config = config or {}
    self.spawnPoints = self.config.spawnPoints or {}
    self.enemiesPerWave = self.config.enemiesPerWave or 5
    self.waveInterval = self.config.waveInterval or 10
    self.enemyTemplate = self.config.enemyTemplate
    return self
end

-- Spawns a single wave of enemies.
function EnemySpawner:SpawnWave(waveNumber)
    print(string.format("Spawning wave %d with %d enemies", waveNumber, self.enemiesPerWave))
    for i = 1, self.enemiesPerWave do
        local spawnPoint = self.spawnPoints[((i - 1) % #self.spawnPoints) + 1]
        if spawnPoint then
            -- Clone the enemy and spawn it at the spawn point.
            local enemyClone = self.enemyTemplate:Clone()
            enemyClone.Parent = workspace
            enemyClone:MoveTo(spawnPoint.Position)
            
            -- Ensure the enemy model has its PrimaryPart set.
            if not enemyClone.PrimaryPart and enemyClone:FindFirstChild("HumanoidRootPart") then
                enemyClone.PrimaryPart = enemyClone.HumanoidRootPart
            end

            -- Gather patrol waypoints from the spawn point's PatrolPoints folder.
            local patrolPoints = {}
            local patrolFolder = spawnPoint:FindFirstChild("PatrolPoints")
            if patrolFolder then
                for _, point in ipairs(patrolFolder:GetChildren()) do
                    if point:IsA("BasePart") then
                        table.insert(patrolPoints, point.Position)
                    end
                end
            else
                warn("No PatrolPoints folder found for spawn point:", spawnPoint.Name)
            end

            -- Start the enemy's AI with these patrol points.
            local EnemyAI = require(game.ServerScriptService.Server.Modules.EnemyAI)
            EnemyAI.StartAI(enemyClone, {
                detectionRadius = 20,
                waypoints = patrolPoints
            })
        end
    end
end

-- Begins continuous wave spawning.
function EnemySpawner:StartSpawning()
    spawn(function()
        local wave = 1
        while true do
            self:SpawnWave(wave)
            wave = wave + 1
            wait(self.waveInterval)
        end
    end)
end

return EnemySpawner