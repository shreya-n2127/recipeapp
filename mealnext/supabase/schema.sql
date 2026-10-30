

drop trigger if exists on_auth_user_created on auth.users;
drop table if exists likes, comments, recipe_ingredients, recipes, ingredients, profiles cascade;

--table
create table profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  username   text not null unique check (char_length(username) between 3 and 20),
  created_at timestamptz not null default now()
);

create table ingredients (
  id   serial primary key,
  name text not null unique
);

create table recipes (
  id            serial primary key,
  title         text not null unique,
  cook_time     text,
  category      text,
  youtube_id    text,
  needs         text,            -- full shopping list, comma separated
  steps         text,            -- numbered method
  like_count    int not null default 0,      -- kept up to date by a trigger
  comment_count int not null default 0,      -- kept up to date by a trigger
  created_at    timestamptz not null default now()
);

create table recipe_ingredients (            -- many-to-many link
  recipe_id     int not null references recipes(id) on delete cascade,
  ingredient_id int not null references ingredients(id) on delete cascade,
  primary key (recipe_id, ingredient_id)
);

create table comments (
  id         bigserial primary key,
  recipe_id  int  not null references recipes(id) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  text       text not null,
  created_at timestamptz not null default now()
);

create table likes (
  recipe_id  int  not null references recipes(id) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (recipe_id, user_id)           -- one like per user per recipe
);


--  Trigger

-- create profile row
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'username'), ''), split_part(new.email, '@', 1))
  );
  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2b. Keep recipes.like_count correct when a like is added or removed.
create or replace function public.update_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update recipes set like_count = like_count + 1 where id = new.recipe_id;
  elsif tg_op = 'DELETE' then
    update recipes set like_count = greatest(like_count - 1, 0) where id = old.recipe_id;
  end if;
  return null;
end; $$;

create trigger trg_like_count
  after insert or delete on likes
  for each row execute function public.update_like_count();

-- 2c. Keep recipes.comment_count correct.
create or replace function public.update_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update recipes set comment_count = comment_count + 1 where id = new.recipe_id;
  elsif tg_op = 'DELETE' then
    update recipes set comment_count = greatest(comment_count - 1, 0) where id = old.recipe_id;
  end if;
  return null;
end; $$;

create trigger trg_comment_count
  after insert or delete on comments
  for each row execute function public.update_comment_count();

-- 2d. Clean and validate every comment BEFORE it is saved.
create or replace function public.clean_comment()
returns trigger language plpgsql as $$
begin
  new.text := trim(new.text);
  if new.text = '' then raise exception 'Comment cannot be empty'; end if;
  if char_length(new.text) > 500 then raise exception 'Comment is too long (max 500)'; end if;
  return new;
end; $$;

create trigger trg_clean_comment
  before insert on comments
  for each row execute function public.clean_comment();


--row security

alter table profiles           enable row level security;
alter table ingredients        enable row level security;
alter table recipes            enable row level security;
alter table recipe_ingredients enable row level security;
alter table comments           enable row level security;
alter table likes              enable row level security;

-- read ingredients
create policy "anyone can read ingredients"        on ingredients        for select using (true);
create policy "anyone can read recipes"            on recipes            for select using (true);
create policy "anyone can read recipe_ingredients" on recipe_ingredients for select using (true);


create policy "anyone can read profiles" on profiles for select using (true);
create policy "update own profile"       on profiles for update
  using (auth.uid() = id) with check (auth.uid() = id);

-- comments_restrictions
create policy "anyone can read comments" on comments for select using (true);
create policy "add own comment"          on comments for insert to authenticated
  with check (auth.uid() = user_id);
create policy "delete own comment"       on comments for delete to authenticated
  using (auth.uid() = user_id);

-- like_restrictions
create policy "anyone can read likes" on likes for select using (true);
create policy "add own like"          on likes for insert to authenticated
  with check (auth.uid() = user_id);
create policy "remove own like"       on likes for delete to authenticated
  using (auth.uid() = user_id);

--ingredient names for matching algo

insert into ingredients (name) values
 ('Onion'),('Tomato'),('Potato'),('Garlic'),('Ginger'),('Rice'),('Egg'),('Milk'),
 ('Butter'),('Flour'),('Cheese'),('Chicken'),('Paneer'),('Pasta'),('Green Chilli'),
 ('Carrot'),('Bread'),('Yogurt'),('Cream'),('Breadcrumbs'),('Coriander Leaves'),('Spring Onion');

--recipe deatils.
--last added recipes go to whats new section on index.html

insert into recipes (title, cook_time, category, youtube_id, needs, steps, created_at) values

('Aloo Fry','20 minutes','Vegetarian','k5B8uNemjXA',
$$Potatoes (3 medium), oil (2 tbsp), cumin seeds (1/2 tsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), salt (to taste)$$,
$$1. Peel the potatoes and cut them into small, even pieces so they cook at the same speed.
2. Heat the oil in a pan and add the cumin seeds. Let them sizzle for a few seconds.
3. Add the potatoes, turmeric powder, chilli powder and salt.
4. Mix well, cover the pan and cook on low heat until the potatoes are soft.
5. Stir occasionally so they don't stick, then serve hot.$$, now() - interval '30 days'),

('Tomato Rice','20 minutes','Vegetarian','eXGgrhtql1A',
$$Cooked rice (2 cups), tomatoes (2), onion (1), oil (2 tbsp), ginger-garlic paste (1 tsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), salt (to taste)$$,
$$1. Chop the onion and tomatoes.
2. Heat the oil in a pan and fry the onion until soft.
3. Add the ginger-garlic paste and cook for one minute until the raw smell goes.
4. Add the tomatoes, turmeric, chilli powder and salt.
5. Cook until the tomatoes turn soft and mushy.
6. Add the cooked rice and mix gently so the grains don't break.
7. Cook for another 2 to 3 minutes and serve.$$, now() - interval '29 days'),

('Egg Bhurji','15 minutes','Non-Vegetarian','UpvIsNxEzW0',
$$Eggs (3), onion (1), tomato (1), green chilli (1), oil (1 tbsp), turmeric powder (1/4 tsp), red chilli powder (1/4 tsp), salt (to taste)$$,
$$1. Beat the eggs in a bowl.
2. Heat the oil in a pan and fry the chopped onion and green chilli.
3. Add the chopped tomato, turmeric, chilli powder and salt.
4. Cook until the tomato becomes soft.
5. Pour in the beaten eggs.
6. Stir continuously until the eggs are fully cooked and crumbly.
7. Serve hot with bread or chapati.$$, now() - interval '28 days'),

('Paneer Butter Masala','30 minutes','Vegetarian','U1LVDFwi8qI',
$$Paneer (200 g), onion (1), tomatoes (2), butter (2 tbsp), ginger-garlic paste (1 tsp), cream (2 tbsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), garam masala (1/2 tsp), salt (to taste)$$,
$$1. Cut the paneer into cubes.
2. Heat the butter in a pan and fry the chopped onion until soft.
3. Add the ginger-garlic paste and cook for one minute.
4. Add the chopped tomatoes, turmeric, chilli powder and salt.
5. Cook until soft, then blend the mixture if you want a smooth gravy.
6. Return the gravy to the pan and add a little water if it is too thick.
7. Add the paneer and garam masala.
8. Stir in the cream and simmer for 3 to 5 minutes.
9. Serve hot with rice or naan.$$, now() - interval '27 days'),

('Chicken Curry','40 minutes','Non-Vegetarian','jwyge5daKUQ',
$$Chicken (500 g), onions (2), tomatoes (2), oil (2 tbsp), ginger-garlic paste (1 tbsp), turmeric powder (1/2 tsp), red chilli powder (1 tsp), coriander powder (1 tsp), garam masala (1/2 tsp), salt (to taste), water (as needed)$$,
$$1. Heat the oil in a pan and fry the chopped onions until golden.
2. Add the ginger-garlic paste and cook for one minute.
3. Add the chopped tomatoes, turmeric, chilli powder, coriander powder and salt.
4. Cook until the tomatoes become soft and the oil starts to separate.
5. Add the chicken and mix well so every piece is coated with masala.
6. Add water, cover and cook until the chicken is thoroughly cooked.
7. Sprinkle the garam masala and simmer for another 2 minutes.
8. Serve hot with rice or chapati.$$, now() - interval '26 days'),

('Cheese Omelette','10 minutes','Vegetarian','-ZnK6OgRqqY',
$$Eggs (2), grated cheese (1/4 cup), onion (2 tbsp), butter (1 tsp), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Beat the eggs with the salt and black pepper.
2. Add the chopped onion and mix.
3. Heat the butter in a non-stick pan.
4. Pour in the egg mixture and cook on low heat.
5. Sprinkle the grated cheese over the eggs.
6. Fold the omelette when the eggs are nearly cooked.
7. Cook until the eggs are fully set and the cheese melts.
8. Serve hot.$$, now() - interval '25 days'),

('Pasta Arrabbiata','25 minutes','Vegetarian','XnGhDm2PCNA',
$$Pasta (200 g), tomatoes (3), garlic (4 cloves), olive oil (2 tbsp), red chilli flakes (1/2 tsp), salt (to taste), black pepper (1/4 tsp)$$,
$$1. Boil the pasta in salted water until cooked. Drain it and keep it aside.
2. Heat the olive oil in a pan and add the chopped garlic.
3. Add the chopped tomatoes, chilli flakes, salt and pepper.
4. Cook until the tomatoes break down into a thick sauce.
5. Add the cooked pasta and mix well.
6. Cook for 2 minutes and serve hot.$$, now() - interval '24 days'),

('Cheese Pasta','20 minutes','Vegetarian','l_HOohJZL0U',
$$Pasta (200 g), butter (2 tbsp), milk (1 cup), grated cheese (1 cup), garlic (2 cloves), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Boil the pasta according to the packet instructions and drain.
2. Melt the butter in a pan and add the chopped garlic.
3. Add the milk and heat gently.
4. Add the grated cheese, salt and pepper.
5. Stir until the cheese melts and the sauce becomes smooth.
6. Add the cooked pasta and mix well.
7. Serve hot.$$, now() - interval '23 days'),

('Plain Paratha','25 minutes','Vegetarian','ynvLEN74PIw',
$$Wheat flour (2 cups), water (as needed), salt (1/2 tsp), oil (1 tsp for dough), oil or ghee (for cooking)$$,
$$1. Mix the wheat flour and salt in a bowl.
2. Add water gradually and knead into a soft dough.
3. Add a teaspoon of oil and knead again.
4. Rest the dough for 10 minutes.
5. Divide it into balls and roll each into a circle.
6. Cook on a hot pan until both sides have light brown spots.
7. Apply a little oil or ghee and cook until golden.
8. Serve hot.$$, now() - interval '22 days'),

('Aloo Paratha','35 minutes','Vegetarian','j1_05wNTUYY',
$$Wheat flour (2 cups), potatoes (3 medium), green chilli (1), coriander leaves (2 tbsp), red chilli powder (1/2 tsp), salt (to taste), water (as needed), oil or ghee (for cooking)$$,
$$1. Boil, peel and mash the potatoes.
2. Mix the potatoes with the chopped green chilli, coriander, chilli powder and salt.
3. Knead the wheat flour with water to make a soft dough.
4. Divide the dough into balls and flatten each one.
5. Place some potato filling in the centre and seal the dough.
6. Roll gently into a paratha so the filling doesn't tear through.
7. Cook on a hot pan with oil or ghee until both sides are golden.
8. Serve hot.$$, now() - interval '21 days'),

('Jeera Rice','20 minutes','Vegetarian','be0ZTJuOEzM',
$$Basmati rice (1 cup), water (2 cups), ghee (1 tbsp), cumin seeds (1 tsp), salt (to taste)$$,
$$1. Wash the rice thoroughly.
2. Heat the ghee in a pot and add the cumin seeds.
3. Add the washed rice and stir gently for one minute.
4. Add the water and salt.
5. Bring to a boil, then cover and cook on low heat until the rice is tender and the water is absorbed.
6. Let it rest for 5 minutes.
7. Fluff with a fork and serve.$$, now() - interval '20 days'),

('Egg Fried Rice','15 minutes','Non-Vegetarian','GfyJS-flQQo',
$$Cooked rice (2 cups), eggs (2), onion (1 small), carrot (1 small), garlic (2 cloves), oil (2 tbsp), soy sauce (1 tbsp), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Beat the eggs in a bowl.
2. Heat a little oil in a pan and scramble the eggs until cooked. Set aside.
3. Heat the remaining oil and fry the chopped garlic and onion.
4. Add the chopped carrot and cook for 2 to 3 minutes.
5. Add the cooked rice, soy sauce, pepper and salt.
6. Add the scrambled eggs and mix well.
7. Stir-fry for another 2 minutes on high heat and serve hot.$$, now() - interval '19 days'),

('Chicken Fried Rice','25 minutes','Non-Vegetarian','ASA7yTRC9NY',
$$Cooked rice (2 cups), boneless chicken (200 g), carrot (1 small), spring onion (2 tbsp), garlic (2 cloves), oil (2 tbsp), soy sauce (1 tbsp), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Cut the chicken into small pieces.
2. Heat the oil in a pan and cook the chicken until thoroughly cooked. Set aside.
3. In the same pan, fry the chopped garlic and carrot.
4. Add the cooked rice, soy sauce, pepper and salt.
5. Add the cooked chicken and mix well.
6. Stir-fry for 2 to 3 minutes.
7. Add the chopped spring onion and serve hot.$$, now() - interval '18 days'),

('Paneer Bhurji','15 minutes','Vegetarian','MUzjIceBV70',
$$Paneer (200 g), onion (1), tomato (1), green chilli (1), oil (1 tbsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), garam masala (1/4 tsp), salt (to taste)$$,
$$1. Crumble the paneer into small pieces.
2. Heat the oil in a pan and fry the chopped onion and green chilli.
3. Add the chopped tomato, turmeric, chilli powder and salt.
4. Cook until the tomato becomes soft.
5. Add the crumbled paneer and garam masala.
6. Mix well and cook for 3 to 4 minutes.
7. Serve hot with chapati or bread.$$, now() - interval '17 days'),

('Mashed Potatoes','25 minutes','Vegetarian','iPSs0SikHwo',
$$Potatoes (3 medium), butter (2 tbsp), milk (1/4 cup), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Peel the potatoes and cut them into pieces.
2. Boil them in water until soft.
3. Drain the water and mash the potatoes.
4. Add the butter, milk, salt and black pepper.
5. Mix until smooth and creamy.
6. Serve warm.$$, now() - interval '16 days'),

('Garlic Bread Topping','15 minutes','Vegetarian','H8MOTK9ztEc',
$$Bread slices (4), butter (3 tbsp), garlic (3 cloves), coriander leaves (1 tbsp), grated cheese (1/2 cup; optional)$$,
$$1. Finely chop or crush the garlic.
2. Mix the garlic with the softened butter and chopped coriander.
3. Spread the mixture evenly over the bread slices.
4. Add grated cheese on top if you like.
5. Toast in a pan or bake until the bread is crisp and golden.
6. Serve warm.$$, now() - interval '15 days'),

('Tomato Soup','25 minutes','Vegetarian','lBhwjjUiFk4',
$$Tomatoes (4), onion (1 small), garlic (2 cloves), butter (1 tbsp), water (2 cups), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Chop the tomatoes, onion and garlic.
2. Melt the butter in a pot and fry the onion and garlic.
3. Add the tomatoes and water.
4. Cover and cook until the tomatoes become soft.
5. Let the mixture cool slightly, then blend until smooth.
6. Return to the pot, add salt and pepper, and simmer for 3 minutes.
7. Serve hot.$$, now() - interval '14 days'),

('Rice Kheer','40 minutes','Vegetarian','835sLyEmqSI',
$$Rice (1/4 cup), milk (1 litre), sugar (1/4 cup), cardamom powder (1/4 tsp), chopped nuts (2 tbsp; optional)$$,
$$1. Wash the rice thoroughly.
2. Bring the milk to a boil in a heavy-bottomed pot.
3. Add the rice and cook on low heat, stirring occasionally so it doesn't stick.
4. Cook until the rice becomes soft and the milk thickens.
5. Add the sugar and cardamom powder.
6. Cook for another 5 minutes.
7. Add chopped nuts if you like and serve warm or chilled.$$, now() - interval '13 days'),

('Pancakes','20 minutes','Vegetarian','1BNQklgelk4',
$$All-purpose flour (1 cup), milk (3/4 cup), egg (1), sugar (2 tbsp), baking powder (1 tsp), butter (2 tbsp), salt (a pinch)$$,
$$1. Mix the flour, sugar, baking powder and salt in a bowl.
2. Add the milk, egg and melted butter.
3. Mix until a smooth batter forms.
4. Heat a lightly greased pan over medium-low heat.
5. Pour a small amount of batter into the pan.
6. Cook until bubbles appear, then flip.
7. Cook the other side until golden and serve.$$, now() - interval '12 days'),

('Butter Chicken','40 minutes','Non-Vegetarian','Hj_n77QoEKE',
$$Boneless chicken (500 g), tomatoes (3), onion (1), butter (3 tbsp), ginger-garlic paste (1 tbsp), cream (1/4 cup), red chilli powder (1 tsp), garam masala (1/2 tsp), salt (to taste)$$,
$$1. Cut the chicken into bite-sized pieces.
2. Heat 1 tablespoon of butter in a pan and cook the chicken until thoroughly cooked. Set aside.
3. In the same pan, cook the chopped onion until soft.
4. Add the ginger-garlic paste, chopped tomatoes, chilli powder and salt.
5. Cook until the tomatoes become soft, then blend the mixture until smooth.
6. Return the gravy to the pan and add the cooked chicken.
7. Add the remaining butter, the cream and the garam masala.
8. Simmer for 5 minutes and serve hot.$$, now() - interval '11 days'),

('Egg Curry','30 minutes','Non-Vegetarian','UzjCJV-dvf0',
$$Eggs (4), onions (2), tomatoes (2), oil (2 tbsp), ginger-garlic paste (1 tsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), coriander powder (1 tsp), salt (to taste), water (1 cup)$$,
$$1. Boil the eggs, peel them and set aside.
2. Heat the oil in a pan and fry the chopped onions until golden.
3. Add the ginger-garlic paste and cook for one minute.
4. Add the chopped tomatoes, turmeric, chilli powder, coriander powder and salt.
5. Cook until the tomatoes become soft.
6. Add the water and simmer to make the gravy.
7. Add the boiled eggs and cook for 5 minutes.
8. Serve hot with rice or chapati.$$, now() - interval '10 days'),

('Potato Cheese Balls','30 minutes','Vegetarian','ZXvwE49ECK0',
$$Potatoes (3 medium), grated cheese (1/2 cup), breadcrumbs (1 cup), cornflour (2 tbsp), black pepper (1/4 tsp), salt (to taste), oil (for frying)$$,
$$1. Boil, peel and mash the potatoes.
2. Mix the potatoes with the cheese, cornflour, pepper and salt.
3. Shape the mixture into small balls.
4. Roll each ball in breadcrumbs.
5. Heat the oil in a pan.
6. Fry the balls until golden and crispy.
7. Drain the excess oil and serve hot.$$, now() - interval '9 days'),

('Chicken Pasta','30 minutes','Non-Vegetarian','4ddqQiV3t8U',
$$Pasta (200 g), boneless chicken (200 g), onion (1 small), tomatoes (2), garlic (2 cloves), oil (2 tbsp), black pepper (1/4 tsp), salt (to taste), grated cheese (1/4 cup; optional)$$,
$$1. Boil the pasta according to the packet instructions and drain.
2. Cut the chicken into small pieces.
3. Heat the oil in a pan and cook the chicken until thoroughly cooked.
4. Add the chopped onion and garlic and fry until soft.
5. Add the chopped tomatoes, salt and pepper.
6. Cook until the tomatoes form a sauce.
7. Add the cooked pasta and mix well.
8. Sprinkle cheese on top if you like and serve hot.$$, now() - interval '8 days'),

('Paneer Paratha','35 minutes','Vegetarian','jMP9Plw-ED8',
$$Wheat flour (2 cups), paneer (200 g), green chilli (1), coriander leaves (2 tbsp), red chilli powder (1/2 tsp), salt (to taste), water (as needed), oil or ghee (for cooking)$$,
$$1. Mix the wheat flour with water and knead into a soft dough.
2. Crumble the paneer in a bowl.
3. Add the chopped green chilli, coriander, chilli powder and salt to the paneer.
4. Divide the dough into balls and flatten each one.
5. Place the paneer filling in the centre and seal the dough.
6. Roll gently into a paratha.
7. Cook on a hot pan with oil or ghee until both sides are golden.
8. Serve hot.$$, now() - interval '7 days'),

('Aloo Tomato Curry','30 minutes','Vegetarian','pPwrUDhySP8',
$$Potatoes (3 medium), tomatoes (2), onion (1), oil (2 tbsp), cumin seeds (1/2 tsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), coriander powder (1 tsp), salt (to taste), water (1 cup)$$,
$$1. Peel the potatoes and cut them into small pieces.
2. Heat the oil in a pan and add the cumin seeds.
3. Add the chopped onion and fry until soft.
4. Add the chopped tomatoes, turmeric, chilli powder, coriander powder and salt.
5. Cook until the tomatoes become soft.
6. Add the potatoes and water.
7. Cover and cook until the potatoes are tender.
8. Serve hot with chapati or rice.$$, now() - interval '6 days'),

('Masala Omelette','10 minutes','Non-Vegetarian','j_RE8pOK8DE',
$$Eggs (2), onion (1 small), tomato (1 small), green chilli (1), coriander leaves (1 tbsp), oil (1 tbsp), turmeric powder (a pinch), red chilli powder (1/4 tsp), salt (to taste)$$,
$$1. Beat the eggs in a bowl.
2. Add the chopped onion, tomato, green chilli and coriander.
3. Add the turmeric, chilli powder and salt, then mix well.
4. Heat the oil in a pan.
5. Pour in the egg mixture and spread it evenly.
6. Cook until the bottom is set, then flip carefully.
7. Cook until the eggs are fully cooked and serve hot.$$, now() - interval '5 days'),

('Paneer Tikka','35 minutes','Vegetarian','BwIJHI4KdIE',
$$Paneer (250 g), thick yogurt (1/2 cup), ginger-garlic paste (1 tsp), turmeric powder (1/4 tsp), red chilli powder (1/2 tsp), garam masala (1/2 tsp), lemon juice (1 tbsp), salt (to taste), oil (1 tbsp), capsicum (1; optional), onion (1; optional)$$,
$$1. Cut the paneer into cubes.
2. Mix the yogurt, ginger-garlic paste, turmeric, chilli powder, garam masala, lemon juice and salt.
3. Add the paneer and the optional chopped vegetables to the marinade.
4. Let it rest for 15 minutes.
5. Thread the paneer and vegetables onto skewers or place them on a baking tray.
6. Brush lightly with oil.
7. Grill or bake at 200 C until lightly browned, turning halfway through.
8. Serve hot.$$, now() - interval '4 days'),

('Chicken Biryani','60 minutes','Non-Vegetarian','95BCU1n268w',
$$Chicken (500 g), basmati rice (2 cups), onions (2), tomatoes (2), yogurt (1/2 cup), ginger-garlic paste (1 tbsp), biryani masala (1 tbsp), turmeric powder (1/2 tsp), oil (3 tbsp), salt (to taste), water (as needed)$$,
$$1. Wash the rice and soak it for 20 minutes.
2. Heat the oil in a pot and fry the sliced onions until golden.
3. Add the ginger-garlic paste and cook for one minute.
4. Add the chicken, tomatoes, yogurt, biryani masala, turmeric and salt.
5. Cook until the chicken is partly cooked and the masala thickens.
6. In a separate pot, boil the rice until it is about 70% cooked, then drain.
7. Layer the rice over the chicken mixture.
8. Cover tightly and cook on low heat until the rice and chicken are fully cooked.
9. Mix gently before serving.$$, now() - interval '3 days'),

('Potato Soup','30 minutes','Vegetarian','7xIOxT7uti8',
$$Potatoes (3 medium), onion (1), garlic (2 cloves), butter (1 tbsp), milk (1/2 cup), water or vegetable stock (3 cups), black pepper (1/4 tsp), salt (to taste)$$,
$$1. Peel and chop the potatoes.
2. Melt the butter in a pot and fry the chopped onion and garlic.
3. Add the potatoes and the water or vegetable stock.
4. Cover and cook until the potatoes become soft.
5. Blend the soup until smooth, or mash the potatoes for a thicker texture.
6. Add the milk, salt and pepper.
7. Heat gently for 3 to 4 minutes without boiling vigorously.
8. Serve warm.$$, now() - interval '2 days'),

('Chicken Cutlet','35 minutes','Non-Vegetarian','BbXX2NArL9w',
$$Boneless chicken (300 g), potato (1 medium), onion (1 small), ginger-garlic paste (1 tsp), breadcrumbs (1 cup), egg (1), black pepper (1/4 tsp), salt (to taste), oil (for frying)$$,
$$1. Cook the chicken thoroughly and shred it into small pieces.
2. Boil, peel and mash the potato.
3. Mix the chicken with the mashed potato, chopped onion, ginger-garlic paste, pepper and salt.
4. Shape the mixture into flat cutlets.
5. Beat the egg in a bowl.
6. Dip each cutlet in the egg and coat with breadcrumbs.
7. Heat the oil in a pan and fry the cutlets until golden on both sides.
8. Serve hot.$$, now() - interval '1 days');

-- --main ingredient for each recipe. M to M relationship

insert into recipe_ingredients (recipe_id, ingredient_id)
select r.id, i.id
from (values
  ('Aloo Fry',              array['Potato']),
  ('Tomato Rice',           array['Rice','Tomato','Onion','Ginger','Garlic']),
  ('Egg Bhurji',            array['Egg','Onion','Tomato','Green Chilli']),
  ('Paneer Butter Masala',  array['Paneer','Onion','Tomato','Butter','Ginger','Garlic','Cream']),
  ('Chicken Curry',         array['Chicken','Onion','Tomato','Ginger','Garlic']),
  ('Cheese Omelette',       array['Egg','Cheese','Butter','Onion']),
  ('Pasta Arrabbiata',      array['Pasta','Tomato','Garlic']),
  ('Cheese Pasta',          array['Pasta','Butter','Milk','Cheese','Garlic']),
  ('Plain Paratha',         array['Flour']),
  ('Aloo Paratha',          array['Flour','Potato','Green Chilli','Coriander Leaves']),
  ('Jeera Rice',            array['Rice']),
  ('Egg Fried Rice',        array['Rice','Egg','Onion','Carrot','Garlic']),
  ('Chicken Fried Rice',    array['Rice','Chicken','Carrot','Spring Onion','Garlic']),
  ('Paneer Bhurji',         array['Paneer','Onion','Tomato','Green Chilli']),
  ('Mashed Potatoes',       array['Potato','Butter','Milk']),
  ('Garlic Bread Topping',  array['Bread','Butter','Garlic','Coriander Leaves','Cheese']),
  ('Tomato Soup',           array['Tomato','Onion','Garlic','Butter']),
  ('Rice Kheer',            array['Rice','Milk']),
  ('Pancakes',              array['Flour','Milk','Egg','Butter']),
  ('Butter Chicken',        array['Chicken','Tomato','Onion','Butter','Ginger','Garlic','Cream']),
  ('Egg Curry',             array['Egg','Onion','Tomato','Ginger','Garlic']),
  ('Potato Cheese Balls',   array['Potato','Cheese','Breadcrumbs']),
  ('Chicken Pasta',         array['Pasta','Chicken','Onion','Tomato','Garlic','Cheese']),
  ('Paneer Paratha',        array['Flour','Paneer','Green Chilli','Coriander Leaves']),
  ('Aloo Tomato Curry',     array['Potato','Tomato','Onion']),
  ('Masala Omelette',       array['Egg','Onion','Tomato','Green Chilli','Coriander Leaves']),
  ('Paneer Tikka',          array['Paneer','Yogurt','Ginger','Garlic','Onion']),
  ('Chicken Biryani',       array['Chicken','Rice','Onion','Tomato','Yogurt','Ginger','Garlic']),
  ('Potato Soup',           array['Potato','Onion','Garlic','Butter','Milk']),
  ('Chicken Cutlet',        array['Chicken','Potato','Onion','Ginger','Garlic','Breadcrumbs','Egg'])
) as v(title, ings)
cross join lateral unnest(v.ings) as n(name)
join recipes r     on r.title = v.title
join ingredients i on i.name  = n.name;

-- showing 30 recipes, 22 ingredients
select (select count(*) from recipes) as recipes, (select count(*) from ingredients) as ingredients,
       (select count(*) from recipe_ingredients) as links;
