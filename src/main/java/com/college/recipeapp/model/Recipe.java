package com.college.recipeapp.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.*;

    @Entity
    public class Recipe {
        @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;
        private String title;
        @Column(length = 3000)
        private String instructions;
        private String youtubeId;
        private LocalDateTime createdAt = LocalDateTime.now();

        @ManyToMany
        @JoinTable(name = "recipe_ingredient",
                joinColumns = @JoinColumn(name = "recipe_id"),
                inverseJoinColumns = @JoinColumn(name = "ingredient_id"))
        private Set<Ingredient> ingredients = new HashSet<>();

        @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true)
        @OrderBy("createdAt DESC")
        private List<Comment> comments = new ArrayList<>();

        @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true)
        private Set<RecipeLike> likes = new HashSet<>();

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getInstructions() { return instructions; }
        public void setInstructions(String instructions) { this.instructions = instructions; }
        public String getYoutubeId() { return youtubeId; }
        public void setYoutubeId(String youtubeId) { this.youtubeId = youtubeId; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
        public Set<Ingredient> getIngredients() { return ingredients; }
        public void setIngredients(Set<Ingredient> ingredients) { this.ingredients = ingredients; }
        public List<Comment> getComments() { return comments; }
        public void setComments(List<Comment> comments) { this.comments = comments; }
        public Set<RecipeLike> getLikes() { return likes; }
        public void setLikes(Set<RecipeLike> likes) { this.likes = likes; }
    }

