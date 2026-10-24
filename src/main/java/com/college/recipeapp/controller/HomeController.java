package com.college.recipeapp.controller;

import com.college.recipeapp.repository.RecipeRepository;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    private final RecipeRepository recipeRepo;

    public HomeController(RecipeRepository recipeRepo) {
        this.recipeRepo = recipeRepo;
    }

    @GetMapping("/")
    @Transactional(readOnly = true)
    public String home(Model model) {
        model.addAttribute("newRecipes", recipeRepo.findTop6ByOrderByCreatedAtDesc());
        model.addAttribute("recipes", recipeRepo.findAll());
        return "home";
    }
}