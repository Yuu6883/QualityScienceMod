local recycling = require("__recycler__.recycling")

local quality_science_drain_table = {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 4,
    ["epic"] = 8,
    ["legendary"] = 16,
}

local function add_recipe_category(recipe, category)
    recipe.categories = recipe.categories or {"crafting"}
    table.insert(recipe.categories, category)
end

local function scale_recipe(recipe, scale)

    for _, ingredient in pairs(recipe.ingredients) do
        ingredient.amount = ingredient.amount * scale
        if ingredient.ignored_by_stats and ingredient.ignored_by_stats > 0 then
            ingredient.ignored_by_stats = math.floor(ingredient.ignored_by_stats * scale)
        end
    end
    for _, result in pairs(recipe.results) do
        total = (result.amount + (result.extra_count_fraction or 0)) * scale
        result.amount = math.floor(total)

        if total - result.amount > 0.000001 then
            result.extra_count_fraction = total - result.amount
        else
            result.extra_count_fraction = nil
        end

        if result.ignored_by_stats and result.ignored_by_stats > 0 then
            result.ignored_by_stats =  math.floor(result.ignored_by_stats * scale)
        end
    end
    recipe.energy_required = (recipe.energy_required or 0.5) * scale
end

local function get_quality_tier(quality)
    local prev = nil
    for _, q in pairs(data.raw.quality) do
        if q.next == quality then
            prev = q
            break
        end
    end
    if not prev then
        return 0
    else
        return get_quality_tier(prev.name) + 1
    end
end

local function add_quality_science_scaling(recipe, scaling_map, recipe_scale)
    local subgroup = "quality-" .. recipe

    recipe_scale = recipe_scale or 1

    local locale_prefix = nil
    if data.raw.item[recipe] then
        locale_prefix = "item-name"
    elseif data.raw.fluid[recipe] then
        locale_prefix = "fluid-name"
    else
        locale_prefix = "recipe-name"
    end

    local results = {["normal"] = data.raw.recipe[recipe]}

    -- for compatibility with old recipes
    -- for _, ingredient in pairs(data.raw.recipe[recipe].ingredients) do
    --     if ingredient.type == "item" then
    --         ingredient.quality_min = "normal"
    --         ingredient.quality_max = "normal"
    --     end
    -- end

    for quality, scale in pairs(scaling_map) do
        local new_recipe = util.table.deepcopy(data.raw.recipe[recipe])

        local icon = data.raw.recipe[recipe].icon
        if not icon then
            if data.raw.recipe[recipe].icons then
                icon = util.table.deepcopy(data.raw.recipe[recipe].icons)
            else
                primary_output = data.raw.recipe[recipe].results[1]
                icon = {{icon = data.raw[primary_output.type][primary_output.name].icon }}
            end
        else
            icon = {{icon = icon}}
        end

        for _, ingredient in pairs(new_recipe.ingredients) do
            if ingredient.type == "item" then
                ingredient.quality_min = quality
                ingredient.quality_max = quality
            end

            if ingredient.ignored_by_stats and ingredient.ignored_by_stats > 0 then
                ingredient.ignored_by_stats = ingredient.ignored_by_stats * scale
            end
        end

        for _, result in pairs(new_recipe.results) do
            if result.type == "item" then
                result.quality_min = quality
            end
            result.amount = result.amount * scale / quality_science_drain_table[quality]

            if result.ignored_by_stats and result.ignored_by_stats > 0 then
                result.ignored_by_stats = result.ignored_by_stats * scale
            end

            if recipe_scale == 1 then
                result.amount = math.floor(result.amount)
            end
        end

        new_recipe.name = recipe .. "-" .. quality
        table.insert(icon, {
            icon = data.raw.quality[quality].icon,
            scale = 0.25,
            shift = {-8, 8}
        })
        new_recipe.icons = icon

        local order = new_recipe.order
        if not order then
            if data.raw.item[recipe] then
                order = data.raw.item[recipe].order
            elseif data.raw.fluid[recipe] then
                order = data.raw.fluid[recipe].order
            end
        end

        if order then
            new_recipe.order = order .. "-" .. 
                    string.char(string.byte("a") + get_quality_tier(quality)) .. "[" .. quality .. "]"
        end

        new_recipe.localised_name = {"", "[quality=" .. quality .. "] ", {locale_prefix .. "." .. recipe}}
        -- new_recipe.localised_description = {item}
        new_recipe.enabled = true

        if subgroup then
            if not data.raw["item-subgroup"][subgroup] then
                local subgroup_order = "z"
                if order then
                    subgroup_order = string.sub(order, 1, 1)
                end

                data:extend({{
                    type = "item-subgroup",
                    name = subgroup,
                    group = "quality-science-pack",
                    order = subgroup_order
                }})
            end
            new_recipe.subgroup = subgroup
        end

        if recipe_scale > 1 then
            scale_recipe(new_recipe, recipe_scale)
        end

        data:extend({new_recipe})
        results[quality] = new_recipe
    end

    return results
end

-- change drain multiplier on quality science packs
data.raw.quality.normal.tool_durability_multiplier = 1
data.raw.quality.uncommon.tool_durability_multiplier = 2
data.raw.quality.rare.tool_durability_multiplier = 4
data.raw.quality.epic.tool_durability_multiplier = 8
data.raw.quality.legendary.tool_durability_multiplier = 16

-- FIH
data.raw.recipe["fish-breeding"].allow_productivity = true
data.raw.recipe["fish-breeding"].maximum_productivity = 1.05
data.raw.recipe["fish-breeding"].energy_required = 36
data.raw.recipe["nutrients-from-fish"].allow_productivity = true
data.raw.recipe["nutrients-from-fish"].energy_required = 12

-- add quality asteroid reprocessing casino back
data.raw.recipe["metallic-asteroid-reprocessing"].allow_quality = true
data.raw.recipe["carbonic-asteroid-reprocessing"].allow_quality = true
data.raw.recipe["oxide-asteroid-reprocessing"].allow_quality = true

-- add quality asteroid crushing casino back
data.raw.recipe["metallic-asteroid-crushing"].results[2].independent_probability = 0.2
data.raw.recipe["metallic-asteroid-crushing"].results[2].ignored_by_stats = nil
data.raw.recipe["metallic-asteroid-crushing"].ingredients[1].ignored_by_stats = nil

data.raw.recipe["carbonic-asteroid-crushing"].results[2].independent_probability = 0.2
data.raw.recipe["carbonic-asteroid-crushing"].results[2].ignored_by_stats = nil
data.raw.recipe["carbonic-asteroid-crushing"].ingredients[1].ignored_by_stats = nil

data.raw.recipe["oxide-asteroid-crushing"].results[2].independent_probability = 0.2
data.raw.recipe["oxide-asteroid-crushing"].results[2].ignored_by_stats = nil
data.raw.recipe["oxide-asteroid-crushing"].ingredients[1].ignored_by_stats = nil

-- biter nest patching
local biter_nest = util.table.deepcopy(data.raw["assembling-machine"]["captive-biter-spawner"])
data.raw["assembling-machine"]["captive-biter-spawner"] = nil

biter_nest.type = "furnace"
biter_nest.source_inventory_size = 1
biter_nest.result_inventory_size = 1
biter_nest.fixed_recipe = nil
biter_nest.allowed_effects = {"consumption", "speed", "productivity", "quality"}
biter_nest.module_slots = 4
biter_nest.crafting_categories = {"captive-spawner-process"}

data:extend({biter_nest})
data.raw.recipe["nutrients-from-biter-egg"].allow_quality = true

-- biter egg recipe patching
data.raw.recipe["biter-egg"].energy_required = 100
data.raw.recipe["biter-egg"].ingredients = {
    {type = "item", name = "bioflux", amount = 50},
}
data.raw.recipe["biter-egg"].results = {
    {type = "item", name = "biter-egg", amount = 50},
}

-- decrease quality penalty for speed modules by 4x
data.raw.module["speed-module"].effect.quality = -0.1 * 0.1 * 0.25
data.raw.module["speed-module-2"].effect.quality = -0.15 * 0.1 * 0.25
data.raw.module["speed-module-3"].effect.quality = -0.25 * 0.1 * 0.25

-- capture robot rocket patching to be craftable in biochamber
add_recipe_category(data.raw.recipe["capture-robot-rocket"], "organic")
-- coal synthesis patching to be craftable in biochamber
add_recipe_category(data.raw.recipe["coal-synthesis"], "organic")

-- add module slots to agricultural tower
data.raw["agricultural-tower"]["agricultural-tower"].module_slots = 4
data.raw["agricultural-tower"]["agricultural-tower"].allowed_effects = {"consumption", "speed", "quality"}

-- patch explosives to recycle to ingredients
data.raw.recipe["explosives"].auto_recycle = false
recycling.generate_recycling_recipe(data.raw.recipe["explosives"], function() return true end)

-- patch biolab to recycle to ingredients and craftable in biochamber
data.raw.recipe["biolab"].auto_recycle = false
recycling.generate_recycling_recipe(data.raw.recipe["biolab"], function() return true end)
add_recipe_category(data.raw.recipe["biolab"], "organic")

-- patch biter spawner to recycle to ingredients
data.raw.recipe["captive-biter-spawner"].auto_recycle = false
recycling.generate_recycling_recipe(data.raw.recipe["captive-biter-spawner"], function() return true end)

-- make foundry smelt regular furnace recipes
table.insert(data.raw["assembling-machine"]["foundry"].crafting_categories, "smelting")

-- unlock promethium smelting recipe and patch science pack
table.insert(data.raw.technology["promethium-science-pack"].effects, {
    type = "unlock-recipe", recipe = "promethium-chunk-smelting"})

local legacy_promethium = table.deepcopy(data.raw.recipe["promethium-science-pack"])
data.raw.recipe["promethium-science-pack"].energy_required = 25
data.raw.recipe["promethium-science-pack"].ingredients[1] = {
    type = "fluid", name = "molten-promethium", amount = 3600 }

-- speedup ice platform recipe and add it to cryoplant
data.raw.recipe["ice-platform"].energy_required = 10
add_recipe_category(data.raw.recipe["ice-platform"], "cryogenics")
data.raw.recipe["ice-platform"].allow_productivity = true

-- holmium-solution in biochamber
add_recipe_category(data.raw.recipe["holmium-solution"], "organic")

-- per quality scrap-recycling and holmium-solution prod scaling, unused

-- local scrap_recipes = add_quality_science_scaling("scrap-recycling", {
--     ["uncommon"] = 1,
--     ["rare"] = 1,
--     ["epic"] = 1,
--     ["legendary"] = 1,
-- })

-- local scrap_prod_scaling = {
--     ["normal"] = 1,
--     ["uncommon"] = 2,
--     ["rare"] = 4,
--     ["epic"] = 8,
--     ["legendary"] = 16,
-- }

-- data.raw.technology["scrap-recycling-productivity"].effects = {}

-- for quality, scrap_recipe in pairs(scrap_recipes) do
--     scrap_recipe.maximum_productivity = 1000000

--     table.insert(data.raw.technology.recycling.effects, {
--         type = "unlock-recipe",
--         recipe = scrap_recipe.name,
--     })
--     table.insert(data.raw.technology["scrap-recycling-productivity"].effects, {
--         type = "change-recipe-productivity",
--         recipe = scrap_recipe.name,
--         change = scrap_prod_scaling[quality] * 0.1
--     })
-- end

-- holmium_solution_recipes = add_quality_science_scaling("holmium-solution", {
--     ["uncommon"] = 2,
--     ["rare"] = 4,
--     ["epic"] = 8,
--     ["legendary"] = 16,
-- })

-- for _, holmium_solution_recipe in pairs(holmium_solution_recipes) do
--     table.insert(data.raw.technology["holmium-processing"].effects, {
--         type = "unlock-recipe",
--         recipe = holmium_solution_recipe.name,
--     })
-- end

-- train buffs
data.raw["cargo-wagon"]["cargo-wagon"].inventory_size = 500
data.raw["fluid-wagon"]["fluid-wagon"].capacity = 625000

data.raw.quality.uncommon.locomotive_power_multiplier = 2
data.raw.quality.rare.locomotive_power_multiplier = 3
data.raw.quality.epic.locomotive_power_multiplier = 4
data.raw.quality.legendary.locomotive_power_multiplier = 6

data.raw.quality.uncommon.rolling_stock_max_speed_multiplier = 2
data.raw.quality.rare.rolling_stock_max_speed_multiplier = 3
data.raw.quality.epic.rolling_stock_max_speed_multiplier = 4
data.raw.quality.legendary.rolling_stock_max_speed_multiplier = 6

-- no double labs
data.raw.technology["research-productivity"].unit.time = 60

-- quality scaling
add_quality_science_scaling("automation-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("logistic-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("military-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 12,
    ["epic"] = 40,
    ["legendary"] = 100,
}, 16)

add_quality_science_scaling("chemical-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 4,
    ["epic"] = 10,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("production-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("utility-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("space-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 1.6,
    ["rare"] = 3,
    ["epic"] = 4.8,
    ["legendary"] = 8,
}, 16)

add_quality_science_scaling("electromagnetic-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("metallurgic-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 6,
    ["epic"] = 12,
    ["legendary"] = 25,
}, 16)

add_quality_science_scaling("agricultural-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2.5,
    ["rare"] = 7.5,
    ["epic"] = 25,
    ["legendary"] = 100,
}, 16)

add_quality_science_scaling("cryogenic-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 4,
    ["epic"] = 12,
    ["legendary"] = 30,
}, 16)

add_quality_science_scaling("promethium-science-pack", {
    ["normal"] = 1,
    ["uncommon"] = 1.5,
    ["rare"] = 2,
    ["epic"] = 4,
    ["legendary"] = 8,
}, 4)

-- restore legacy promethium science pack
data:extend({legacy_promethium})

-- hardcoded recipe scaling for now, until I make an automatic scalec for intermediates and their recycling recipes
local scale_16_recipes = {
    "iron-plate",
    "copper-plate",
    "steel-plate",
    "casting-steel",
    "plastic-bar",
    "battery",
    "iron-gear-wheel",
    "casting-iron-gear-wheel",
    "iron-stick",
    "casting-iron-stick",
    "copper-cable",
    "electronic-circuit",
    "advanced-circuit",
    "pipe",
    "casting-pipe",
    "tungsten-carbide",
    "tungsten-plate",
    "quantum-processor",
    "lithium",
    "lithium-plate",
    "solid-fuel-from-ammonia",
    "ammoniacal-solution-separation",
    -- recycling recipes
    "sulfur-recycling",
    "nutrients-recycling",
    "iron-ore-recycling",
    "copper-ore-recycling",
    "calcite-recycling",
    "coal-recycling",
    "electronic-circuit-recycling",
    "advanced-circuit-recycling",
    "processing-unit-recycling",
    "explosives-recycling",
    "low-density-structure-recycling",
    "solid-fuel-recycling",
    "ice-recycling",
    "iron-gear-wheel-recycling",
    "scrap-recycling",
    "supercapacitor-recycling",
    "quantum-processor-recycling",
}

local scale_8_recipes = {
    "casting-iron",
    "casting-copper",
    "casting-copper-cable",
    "holmium-plate",
    "casting-pipe-to-ground",
    "sulfur",
    "tungsten-ore-recycling",
    "biosulfur",
}

local scale_4_recipes = {
    "iron-bacteria-cultivation",
    "copper-bacteria-cultivation"
}

for _, name in pairs(scale_16_recipes) do
    if not data.raw.recipe[name] then
        error("Recipe " .. name .. " not found")
    end
    scale_recipe(data.raw.recipe[name], 16)
end

for _, name in pairs(scale_8_recipes) do
    if not data.raw.recipe[name] then
        error("Recipe " .. name .. " not found")
    end
    scale_recipe(data.raw.recipe[name], 8)
end

for _, name in pairs(scale_4_recipes) do
    if not data.raw.recipe[name] then
        error("Recipe " .. name .. " not found")
    end
    scale_recipe(data.raw.recipe[name], 4)
end

-- data.raw.recipe["iron-ore-recycling"].ingredients[1].ignored_by_stats = 16
-- data.raw.recipe["iron-ore-recycling"].results[1].independent_probability = nil
-- data.raw.recipe["iron-ore-recycling"].results[1].amount = 16
-- data.raw.recipe["iron-ore-recycling"].results[1].ignored_by_stats = 16

-- shattered planet trip fixes for ups
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

local shattered_planet_trip_fixed = util.table.deepcopy(asteroid_util.shattered_planet_trip)

shattered_planet_trip_fixed.probability_on_range_huge   =
{
    {position = 0.001, probability = asteroid_util.system_edge_huge, angle_when_stopped = asteroid_util.huge_angle},
    {position = 0.1,   probability = 0.011, angle_when_stopped = asteroid_util.huge_angle},
    {position = 0.5,   probability = 0.035, angle_when_stopped = asteroid_util.huge_angle},
    {position = 0.999, probability = 0.111, angle_when_stopped = asteroid_util.huge_angle}
}

shattered_planet_trip_fixed.type_ratios = {
    {position = 0.001, ratios = util.table.deepcopy(asteroid_util.system_edge_ratio)},
    {position = 0.002, ratios = { 3/10*16,5/10*16,2/10*16,  0.04  }},-- 3 5 2
    {position = 0.2,   ratios = { 5,3,8,    0.40 }},
    {position = 0.3,   ratios = { 3,9,4,    2.03 }},
    {position = 0.4,   ratios = { 7,6,3,    6.40 }},
    {position = 0.5,   ratios = { 9,2,5,   15.63 }},
    {position = 0.6,   ratios = { 2,6,8,   32.40 }},
    {position = 0.7,   ratios = { 8,2,5,   60.03 }},
    {position = 0.8,   ratios = { 3,9,4,  102.40 }},
    {position = 0.999, ratios = { 10,2,4, 164.03 }},
}

for _, def in pairs(shattered_planet_trip_fixed.type_ratios) do
    def.ratios[4] = math.max(def.position * 250, math.min(def.ratios[4] * 10, 30))
end

data.raw["space-location"]["shattered-planet"].asteroid_spawn_definitions = 
    asteroid_util.spawn_definitions(shattered_planet_trip_fixed, 0.8)

data.raw["space-connection"]["solar-system-edge-shattered-planet"].asteroid_spawn_definitions = 
    asteroid_util.spawn_definitions(shattered_planet_trip_fixed)

    
data.raw["utility-constants"]["default"].maximum_quality_jump = 1
data.raw["module"]["quality-module-3"].effect.quality = 0.0325

