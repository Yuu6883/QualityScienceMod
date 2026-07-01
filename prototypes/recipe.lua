data:extend({
{
    type = "recipe",
    name = "promethium-chunk-smelting",
    localised_name = {"recipe-name.promethium-chunk-smelting"},
    icon = "__Quality_Science_Patch__/graphics/icons/recipe/promethium-smelting.png",
    energy_required = 25,
    surface_conditions =
    {
        {
            property = "gravity",
            min = 0,
            max = 0
        }
    },
    enabled = false,
    allow_productivity = true,
    categories = {"smelting"},
    ingredients =
    {
        { type = "item", name = "promethium-asteroid-chunk", amount = 10 },
    },
    results =
    {
        { type = "fluid", name = "molten-promethium", amount = 600 },
    },
}
})