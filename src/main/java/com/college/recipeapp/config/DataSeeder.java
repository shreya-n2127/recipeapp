package com.college.recipeapp.config;

import com.college.recipeapp.model.Ingredient;
import com.college.recipeapp.model.Recipe;
import com.college.recipeapp.repository.IngredientRepository;
import com.college.recipeapp.repository.RecipeRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@Order(1)
@Component
public class DataSeeder implements CommandLineRunner {

    private final IngredientRepository ingredientRepo;
    private final RecipeRepository recipeRepo;
    private final Map<String, Ingredient> ing = new LinkedHashMap<>();
    private int counter = 0;

    public DataSeeder(IngredientRepository ingredientRepo, RecipeRepository recipeRepo) {
        this.ingredientRepo = ingredientRepo;
        this.recipeRepo = recipeRepo;
    }

    @Override
    public void run(String... args) {
        if (ingredientRepo.count() > 0) {
            System.out.println(">>> Data already exists: " + ingredientRepo.count() + " ingredients, "
                    + recipeRepo.count() + " recipes.");
            return;
        }

        String[] names = {"Onion", "Tomato", "Potato", "Garlic", "Ginger", "Rice", "Egg",
                "Milk", "Butter", "Flour", "Cheese", "Chicken", "Paneer", "Pasta", "Green Chilli"};
        for (String n : names) ing.put(n, ingredientRepo.save(new Ingredient(n)));

        add("Aloo Fry", "Cut potatoes into cubes. Fry garlic, onion and chilli in oil. Add potatoes, salt and turmeric. Cover and cook until soft and crispy.", "", "Potato", "Onion", "Green Chilli", "Garlic");
        add("Tomato Rice", "Saute onion, chilli and tomato until mushy. Add cooked rice, salt and spices. Mix well and serve hot.", "", "Rice", "Tomato", "Onion", "Green Chilli");
        add("Egg Bhurji", "Saute onion, tomato and chilli. Add beaten eggs and scramble until set. Serve with bread or roti.", "", "Egg", "Onion", "Tomato", "Green Chilli");
        add("Paneer Butter Masala", "Blend cooked onion, tomato, garlic and ginger. Simmer in butter, add paneer cubes and cream. Cook 5 minutes.", "", "Paneer", "Butter", "Tomato", "Onion", "Garlic", "Ginger");
        add("Chicken Curry", "Fry onion, ginger and garlic. Add tomato and spices. Add chicken and simmer 25 minutes until tender.", "", "Chicken", "Onion", "Tomato", "Ginger", "Garlic");
        add("Cheese Omelette", "Whisk eggs with salt. Cook in butter, sprinkle cheese on top, fold and serve.", "", "Egg", "Cheese", "Butter");
        add("Pasta Arrabbiata", "Boil pasta. Fry garlic and chilli, add chopped tomato and cook into a sauce. Toss pasta in the sauce.", "", "Pasta", "Tomato", "Garlic", "Green Chilli");
        add("Cheese Pasta", "Make a white sauce with butter, flour and milk. Stir in cheese. Add boiled pasta and mix.", "", "Pasta", "Cheese", "Milk", "Butter", "Flour");
        add("Plain Paratha", "Knead flour dough. Roll, brush with butter, fold into a triangle and roll again. Cook on a hot tawa.", "", "Flour", "Butter");
        add("Aloo Paratha", "Mix mashed potato with chilli and salt. Stuff into flour dough, roll and cook with butter.", "", "Flour", "Potato", "Green Chilli", "Butter");
        add("Jeera Rice", "Heat butter, add cumin seeds. Add washed rice and water, cook until fluffy.", "", "Rice", "Butter");
        add("Egg Fried Rice", "Scramble eggs and set aside. Fry garlic and onion, add cooked rice and eggs. Season and toss on high heat.", "", "Rice", "Egg", "Onion", "Garlic");
        add("Chicken Fried Rice", "Cook diced chicken with garlic and onion. Add egg and cooked rice. Season and toss well.", "", "Rice", "Chicken", "Egg", "Garlic", "Onion");
        add("Paneer Bhurji", "Saute onion, tomato and chilli. Add crumbled paneer and spices. Cook 5 minutes.", "", "Paneer", "Onion", "Tomato", "Green Chilli");
        add("Mashed Potatoes", "Boil potatoes until soft. Mash with butter, warm milk and salt until smooth.", "", "Potato", "Butter", "Milk");
        add("Garlic Bread Topping", "Mix butter, chopped garlic and cheese. Spread on bread and bake until golden.", "", "Garlic", "Butter", "Cheese");
        add("Tomato Soup", "Saute onion and garlic in butter. Add chopped tomato and water, simmer, blend and strain.", "", "Tomato", "Onion", "Garlic", "Butter");
        add("Rice Kheer", "Simmer rice in milk on low heat, stirring often, until thick. Sweeten with sugar and add cardamom.", "", "Rice", "Milk");
        add("Pancakes", "Whisk flour, egg, milk and melted butter into a batter. Cook small rounds on a pan until golden on both sides.", "", "Flour", "Egg", "Milk", "Butter");
        add("Butter Chicken", "Marinate chicken, grill or fry it. Simmer in a sauce of tomato, butter, ginger and garlic.", "", "Chicken", "Butter", "Tomato", "Ginger", "Garlic");
        add("Egg Curry", "Boil eggs. Make a gravy of onion, tomato, ginger and garlic with spices. Add eggs and simmer.", "", "Egg", "Onion", "Tomato", "Ginger", "Garlic");
        add("Potato Cheese Balls", "Mix mashed potato, cheese and flour. Shape into balls and deep fry until golden.", "", "Potato", "Cheese", "Flour");
        add("Chicken Pasta", "Cook chicken with garlic. Add boiled pasta and grated cheese. Toss until melted.", "", "Pasta", "Chicken", "Garlic", "Cheese");
        add("Paneer Paratha", "Mix grated paneer with chilli and salt. Stuff into dough, roll and cook on a tawa.", "", "Flour", "Paneer", "Green Chilli");
        add("Aloo Tomato Curry", "Fry onion and ginger. Add tomato, spices and potato cubes. Add water and cook until soft.", "", "Potato", "Tomato", "Onion", "Ginger");
        add("Masala Omelette", "Mix eggs with chopped onion, tomato and chilli. Pour onto a hot pan and cook both sides.", "", "Egg", "Onion", "Tomato", "Green Chilli");
        add("Paneer Tikka", "Marinate paneer and onion pieces with ginger, garlic and spices. Grill or pan-fry until charred.", "", "Paneer", "Onion", "Ginger", "Garlic");
        add("Chicken Biryani", "Marinate chicken with spices. Layer with half-cooked rice and fried onions. Cook covered on low heat.", "", "Chicken", "Rice", "Onion", "Ginger", "Garlic");
        add("Potato Soup", "Saute onion in butter, add potato cubes and water. Cook, blend, and stir in milk.", "", "Potato", "Milk", "Butter", "Onion");
        add("Chicken Cutlet", "Mix boiled shredded chicken with mashed potato, onion and spices. Shape, dip in egg, and shallow fry.", "", "Chicken", "Potato", "Egg", "Onion");

        System.out.println(">>> Seeded " + ingredientRepo.count() + " ingredients and "
                + recipeRepo.count() + " recipes.");
    }

    private void add(String title, String instructions, String url, String... ingredientNames) {
        Recipe r = new Recipe();
        r.setTitle(title);
        r.setInstructions(instructions);
        r.setYoutubeId(extractYoutubeId(url));
        r.setCreatedAt(LocalDateTime.now().minusDays(30 - counter++));
        for (String n : ingredientNames) r.getIngredients().add(ing.get(n));
        recipeRepo.save(r);
    }

    private String extractYoutubeId(String url) {
        if (url == null || url.isBlank()) return "";
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