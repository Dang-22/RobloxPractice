local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.Start()
    :catch(function(err)
        warn("Knit failed to start", err)
    end)