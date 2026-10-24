package com.college.recipeapp.repository;



import com.college.recipeapp.model.Ingredient;
import org.springframework.data.jpa.repository.JpaRepository;

    public interface IngredientRepository extends JpaRepository<Ingredient, Long> {
    }

