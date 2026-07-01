data:extend({
{
    type = "technology",
    name = "bioflux-productivity",
    icons = util.technology_icon_constant_recipe_productivity("__space-age__/graphics/technology/bacteria-cultivation.png"),
    icon_size = 256,
    effects =
    {
        {
            type = "change-recipe-productivity",
            recipe = "bioflux",
            change = 0.1
        },
        {
            type = "change-recipe-productivity",
            recipe = "iron-bacteria-cultivation",
            change = 0.1
        },
        {
            type = "change-recipe-productivity",
            recipe = "copper-bacteria-cultivation",
            change = 0.1
        },
        {
            type = "change-recipe-productivity",
            recipe = "biosulfur",
            change = 0.1
        }
    },
    prerequisites = {"agricultural-science-pack", "production-science-pack"},
    unit =
    {
        count_formula = "1.5^L*1000",
        ingredients =
        {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1},
            {"chemical-science-pack", 1},
            {"production-science-pack", 1},
            {"agricultural-science-pack", 1},
        },
        time = 60
    },
    max_level = "infinite",
    upgrade = true
},
{
    type = "technology",
    name = "braking-force-8",
    icons = util.technology_icon_constant_braking_force("__base__/graphics/technology/braking-force.png"),
    effects =
    {
    {
        type = "train-braking-force-bonus",
        modifier = 0.15
    }
    },
    prerequisites = {"braking-force-7", "promethium-science-pack"},
    unit =
    {
        count_formula = "1.5^(L-7)*1000",
        ingredients =
        {
            {"automation-science-pack", 1},
            {"logistic-science-pack", 1},
            {"military-science-pack", 1},
            {"chemical-science-pack", 1},
            {"production-science-pack", 1},
            {"utility-science-pack", 1},
            {"space-science-pack", 1},
            {"metallurgic-science-pack", 1},
            {"electromagnetic-science-pack", 1},
            {"agricultural-science-pack", 1},
            {"cryogenic-science-pack", 1},
            {"promethium-science-pack", 1}
        },
        time = 60
    },
    max_level = "infinite",
    upgrade = true
}
})