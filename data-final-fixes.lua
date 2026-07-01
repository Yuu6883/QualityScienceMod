for k, recipe in pairs(data.raw.recipe) do
    local og_recipe_name = string.match(k, "^(.-)%-recycling$")
    if og_recipe_name then 
        local og_recipe = data.raw.recipe[og_recipe_name]
        if og_recipe then
            local results = og_recipe.results or {}
            if #results == 1 and (results[1].type == "item") then
                local amount = results[1].amount or 1

                og_energy = og_recipe.energy_required
                new_energy = (og_recipe.energy_required or 0.5) / 16 / amount

                if amount > 1 and og_energy ~= new_energy then
                    recipe.energy_required = new_energy
                    log("Patching " .. og_recipe_name .. " recycling by scaling craft time by " .. amount)
                    log("Patching " .. og_recipe_name .. " recycling by scaling energy required from " .. (og_energy or "nil") .. " to " .. recipe.energy_required)
                end
            end
        end
    end
end