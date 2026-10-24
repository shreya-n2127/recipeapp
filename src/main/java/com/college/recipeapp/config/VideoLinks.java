package com.college.recipeapp.config;

import com.college.recipeapp.model.Recipe;
import com.college.recipeapp.repository.RecipeRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

@Order(2)
@Component
public class VideoLinks implements CommandLineRunner {

    private final RecipeRepository recipeRepo;

    public VideoLinks(RecipeRepository recipeRepo) {
        this.recipeRepo = recipeRepo;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Map<String, String> v = new LinkedHashMap<>();
        v.put("Aloo Fry", "https://youtu.be/k5B8uNemjXA");
        v.put("Tomato Rice", "https://youtu.be/eXGgrhtql1A");
        v.put("Egg Bhurji", "https://youtu.be/UpvIsNxEzW0");
        v.put("Paneer Butter Masala", "https://youtu.be/U1LVDFwi8qI");
        v.put("Chicken Curry", "https://youtu.be/jwyge5daKUQ");
        v.put("Cheese Omelette", "https://youtu.be/-ZnK6OgRqqY");
        v.put("Pasta Arrabbiata", "https://youtu.be/XnGhDm2PCNA");
        v.put("Cheese Pasta", "https://youtu.be/l_HOohJZL0U");
        v.put("Plain Paratha", "https://youtu.be/ynvLEN74PIw");
        v.put("Aloo Paratha", "https://youtu.be/j1_05wNTUYY");
        v.put("Jeera Rice", "https://youtu.be/be0ZTJuOEzM");
        v.put("Egg Fried Rice", "https://youtu.be/GfyJS-flQQo");
        v.put("Chicken Fried Rice", "https://youtu.be/ASA7yTRC9NY");
        v.put("Paneer Bhurji", "https://youtu.be/MUzjIceBV70");
        v.put("Mashed Potatoes", "https://youtu.be/iPSs0SikHwo");
        v.put("Garlic Bread Topping", "https://youtu.be/H8MOTK9ztEc");
        v.put("Tomato Soup", "https://youtu.be/lBhwjjUiFk4");
        v.put("Rice Kheer", "https://youtu.be/835sLyEmqSI");
        v.put("Pancakes", "https://youtu.be/1BNQklgelk4");
        v.put("Butter Chicken", "https://youtu.be/Hj_n77QoEKE");
        v.put("Egg Curry", "https://youtu.be/UzjCJV-dvf0");
        v.put("Potato Cheese Balls", "https://youtu.be/ZXvwE49ECK0");
        v.put("Chicken Pasta", "https://youtu.be/4ddqQiV3t8U");
        v.put("Paneer Paratha", "https://youtu.be/jMP9Plw-ED8");
        v.put("Aloo Tomato Curry", "https://youtu.be/pPwrUDhySP8");
        v.put("Masala Omelette", "https://youtu.be/j_RE8pOK8DE");
        v.put("Paneer Tikka", "https://youtu.be/BwIJHI4KdIE");
        v.put("Chicken Biryani", "https://youtu.be/95BCU1n268w");
        v.put("Potato Soup", "https://youtu.be/7xIOxT7uti8");
        v.put("Chicken Cutlet", "https://youtu.be/BbXX2NArL9w");

        int set = 0;
        for (Recipe r : recipeRepo.findAll()) {
            String url = v.get(r.getTitle());
            if (url != null && !url.isBlank()) {
                r.setYoutubeId(extractId(url));
                set++;
            }
        }
        System.out.println(">>> Video links applied to " + set + " recipes.");
    }

    private String extractId(String url) {
        url = url.trim();
        if (url.contains("v=")) {
            String id = url.substring(url.indexOf("v=") + 2);
            int amp = id.indexOf('&');
            return amp > 0 ? id.substring(0, amp) : id;
        }
        if (url.contains("youtu.be/")) {
            String id = url.substring(url.indexOf("youtu.be/") + 9);
            int q = id.indexOf('?');
            return q > 0 ? id.substring(0, q) : id;
        }
        return url;
    }
}