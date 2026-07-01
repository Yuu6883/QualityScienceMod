require("prototypes.fluid")
require("prototypes.recipe")
require("prototypes.technology")

-- revert poop concrete recycle recipe before recycling.lua runs
data.raw.recipe["hazard-concrete"].recycle_to_ingredients_of = nil
data.raw.recipe["refined-hazard-concrete"].recycle_to_ingredients_of = nil

data:extend({
    {
        type = "item-group",
        name = "quality-science-pack",
        order = "z",
        icon = "__Quality_Science_Patch__/graphics/icons/quality-science.png",
        icon_size = 128,
    }
})
