package com.college.recipeapp.repository;


import java.util.Optional;
import com.college.recipeapp.model.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;

    public interface IngredientRepository extends JpaRepository<Ingredient, Long> {
        Optional<Ingredient> findByNameIgnoreCase(String name);
    }

