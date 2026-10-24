package com.college.recipeapp.repository;
import java.util.Optional;
import com.college.recipeapp.model.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

    public interface RecipeRepository extends JpaRepository<Recipe, Long> {
        Optional<Recipe> findByTitle(String title);
        List<Recipe> findTop6ByOrderByCreatedAtDesc();
    }
