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
    self.waypoints = self.config.waypoints or {}
    return self
end

-- Spawns a single wave of enemies.
function EnemySpawner:SpawnWave(waveNumber)
    print(string.format("Spawning wave %d with %d enemies", waveNumber, self.enemiesPerWave))
    for i = 1, self.enemiesPerWave do
        local spawnPoint = self.spawnPoints[((i - 1) % #self.spawnPoints) + 1]
        if spawnPoint then
            local enemyClone = self.enemyTemplate:Clone()
            enemyClone.Parent = workspace
            enemyClone:MoveTo(spawnPoint.Position)
            
            -- Set PrimaryPart if not already set (assumes a "HumanoidRootPart" exists).
            if not enemyClone.PrimaryPart and enemyClone:FindFirstChild("HumanoidRootPart") then
                enemyClone.PrimaryPart = enemyClone.HumanoidRootPart
            end

            -- Start the enemy's AI using the EnemyAI module.
            local EnemyAI = require(game.ServerScriptService.Server.Modules.EnemyAI)
            EnemyAI.StartAI(enemyClone, {
                detectionRadius = 20,
                waypoints = self.waypoints
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