package com.college.recipeapp.controller;

import com.college.recipeapp.model.Ingredient;
import com.college.recipeapp.model.Recipe;
import com.college.recipeapp.repository.IngredientRepository;
import com.college.recipeapp.repository.RecipeRepository;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.*;

@Controller
public class MatchController {

    public static class Match {
        private final Recipe recipe;
        private final int percent;
        private final int have;
        private final int total;
        private final List<String> missing;

        public Match(Recipe recipe, int percent, int have, int total, List<String> missing) {
            this.recipe = recipe;
            this.percent = percent;
            this.have = have;
            this.total = total;
            this.missing = missing;
        }
        public Recipe getRecipe() { return recipe; }
        public int getPercent() { return percent; }
        public int getHave() { return have; }
        public int getTotal() { return total; }
        public List<String> getMissing() { return missing; }
    }

    private final RecipeRepository recipeRepo;
    private final IngredientRepository ingredientRepo;

    public MatchController(RecipeRepository recipeRepo, IngredientRepository ingredientRepo) {
        this.recipeRepo = recipeRepo;
        this.ingredientRepo = ingredientRepo;
    }

    @GetMapping("/match")
    @Transactional(readOnly = true)
    public String match(@RequestParam(required = false) List<Long> have, Model model) {
        Set<Long> selected = have == null ? new HashSet<>() : new HashSet<>(have);

        List<Ingredient> all = new ArrayList<>(ingredientRepo.findAll());
        all.sort(Comparator.comparing(Ingredient::getName));

        List<Match> results = new ArrayList<>();
        if (!selected.isEmpty()) {
            for (Recipe r : recipeRepo.findAll()) {
                int total = r.getIngredients().size();
                int haveCount = 0;
                List<String> missing = new ArrayList<>();
                for (Ingredient i : r.getIngredients()) {
                    if (selected.contains(i.getId())) haveCount++;
                    else missing.add(i.getName());
                }
                int percent = total == 0 ? 0 : Math.round(haveCount * 100f / total);
                if (haveCount > 0) results.add(new Match(r, percent, haveCount, total, missing));
            }
            results.sort(Comparator.comparingInt(Match::getPercent).reversed()
                    .thenComparing(m -> m.getRecipe().getTitle()));
        }

        model.addAttribute("ingredients", all);
        model.addAttribute("selected", selected);
        model.addAttribute("results", results);
        model.addAttribute("searched", !selected.isEmpty());
        return "match";
    }
}