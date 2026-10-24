package com.college.recipeapp.controller;

import com.college.recipeapp.model.Comment;
import com.college.recipeapp.model.Recipe;
import com.college.recipeapp.model.RecipeLike;
import com.college.recipeapp.model.User;
import com.college.recipeapp.repository.RecipeRepository;
import com.college.recipeapp.repository.UserRepository;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

@Controller
public class RecipeController {

    private final RecipeRepository recipeRepo;
    private final UserRepository userRepo;

    public RecipeController(RecipeRepository recipeRepo, UserRepository userRepo) {
        this.recipeRepo = recipeRepo;
        this.userRepo = userRepo;
    }

    @GetMapping("/recipe/{id}")
    @Transactional(readOnly = true)
    public String view(@PathVariable Long id, Principal principal, Model model) {
        Recipe r = recipeRepo.findById(id).orElse(null);
        if (r == null) return "redirect:/";
        r.getComments().size();   // load now, while the database session is open
        r.getLikes().size();
        boolean liked = principal != null && r.getLikes().stream()
                .anyMatch(l -> l.getUser().getUsername().equals(principal.getName()));
        model.addAttribute("recipe", r);
        model.addAttribute("likeCount", r.getLikes().size());
        model.addAttribute("liked", liked);
        return "recipe";
    }

    @PostMapping("/recipe/{id}/like")
    @Transactional
    public String like(@PathVariable Long id, Principal principal) {
        Recipe r = recipeRepo.findById(id).orElseThrow();
        User u = userRepo.findByUsername(principal.getName()).orElseThrow();
        boolean removed = r.getLikes().removeIf(l -> l.getUser().getId().equals(u.getId()));
        if (!removed) {
            RecipeLike like = new RecipeLike();
            like.setRecipe(r);
            like.setUser(u);
            r.getLikes().add(like);
        }
        recipeRepo.save(r);
        return "redirect:/recipe/" + id;
    }

    @PostMapping("/recipe/{id}/comment")
    @Transactional
    public String comment(@PathVariable Long id, @RequestParam String text, Principal principal) {
        text = text.trim();
        if (!text.isEmpty() && text.length() <= 500) {
            Recipe r = recipeRepo.findById(id).orElseThrow();
            User u = userRepo.findByUsername(principal.getName()).orElseThrow();
            Comment c = new Comment();
            c.setText(text);
            c.setRecipe(r);
            c.setUser(u);
            r.getComments().add(c);
            recipeRepo.save(r);
        }
        return "redirect:/recipe/" + id;
    }
}