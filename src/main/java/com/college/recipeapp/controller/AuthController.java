package com.college.recipeapp.controller;

import com.college.recipeapp.model.User;
import com.college.recipeapp.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class AuthController {

    private final UserRepository userRepo;
    private final PasswordEncoder encoder;

    public AuthController(UserRepository userRepo, PasswordEncoder encoder) {
        this.userRepo = userRepo;
        this.encoder = encoder;
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }

    @GetMapping("/register")
    public String registerForm() {
        return "register";
    }

    @PostMapping("/register")
    public String register(@RequestParam String username,
                           @RequestParam String password,
                           Model model) {
        username = username.trim();
        if (username.length() < 3 || password.length() < 4) {
            model.addAttribute("error", "Username needs 3+ characters and password 4+.");
            return "register";
        }
        if (userRepo.findByUsername(username).isPresent()) {
            model.addAttribute("error", "That username is already taken.");
            return "register";
        }
        User u = new User();
        u.setUsername(username);
        u.setPassword(encoder.encode(password));
        userRepo.save(u);
        return "redirect:/login?registered";
    }
}