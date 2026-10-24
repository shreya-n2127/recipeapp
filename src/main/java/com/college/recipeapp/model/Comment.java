package com.college.recipeapp.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

    @Entity
    public class Comment {
        @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
        private Long id;
        @Column(length = 500)
        private String text;
        private LocalDateTime createdAt = LocalDateTime.now();

        @ManyToOne(optional = false)
        private Recipe recipe;
        @ManyToOne(optional = false)
        private User user;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getText() { return text; }
        public void setText(String text) { this.text = text; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
        public Recipe getRecipe() { return recipe; }
        public void setRecipe(Recipe recipe) { this.recipe = recipe; }
        public User getUser() { return user; }
        public void setUser(User user) { this.user = user; }
    }

