--
-- chest-source-for-testing
--
local item = table.deepcopy(data.raw["item"]["steel-chest"])
item.name ="chest-source-for-testing"
item.place_result = "chest-source-for-testing"
data:extend{item}

local recipe = table.deepcopy(data.raw.recipe["steel-chest"])
recipe.enabled = true
recipe.name = "chest-source-for-testing"
recipe.result = "chest-source-for-testing"
data:extend{recipe}

local container = table.deepcopy(data.raw["container"]["steel-chest"])
container.name = "chest-source-for-testing"
container.inventory_size = 2000
data:extend{container}

--
-- chest-consumer-for-testing
--
local item = table.deepcopy(data.raw["item"]["steel-chest"])
item.name ="chest-consumer-for-testing"
item.place_result = "chest-consumer-for-testing"
data:extend{item}

local recipe = table.deepcopy(data.raw.recipe["steel-chest"])
recipe.enabled = true
recipe.name = "chest-consumer-for-testing"
recipe.result = "chest-consumer-for-testing"
data:extend{recipe}

local container = table.deepcopy(data.raw["container"]["steel-chest"])
container.name = "chest-consumer-for-testing"
container.inventory_size = 2000
data:extend{container}