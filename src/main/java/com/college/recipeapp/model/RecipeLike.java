package com.college.recipeapp.model;


import jakarta.persistence.*;

    @Entity
    @Table(name = "recipe_like",
            uniqueConstraints = @UniqueConstraint(columnNames = {"recipe_id", "user_id"}))
    public class RecipeLike {
        @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;

        @ManyToOne(optional = false)
        private Recipe recipe;
        @ManyToOne(optional = false)
        private User user;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public Recipe getRecipe() { return recipe; }
        public void setRecipe(Recipe recipe) { this.recipe = recipe; }
        public User getUser() { return user; }
        public void setUser(User user) { this.user = user; }
    }

