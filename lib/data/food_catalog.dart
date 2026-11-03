class FoodServing {
  final String label;
  final double amount;
  const FoodServing(this.label, this.amount);
}

class FoodItem {
  final String name;
  final String category;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final String unit;
  final List<FoodServing> servings;

  const FoodItem({
    required this.name,
    required this.category,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.unit = 'g',
    this.servings = const [],
  });
}

class FoodCatalog {
  static const categories = [
    'All', 'Protein', 'Grains', 'Legumes', 'Fruit', 'Veggies',
    'Dairy', 'Fats & Nuts', 'Meals', 'Drinks', 'Snacks',
  ];

  static List<FoodItem> search(String query, String category) {
    var result = all;
    if (category != 'All') {
      result = result.where((f) => f.category == category).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((f) => f.name.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  static const List<FoodItem> all = [
    // ─── PROTEIN ─────────────────────────────────────
    FoodItem(name: 'Chicken Breast (cooked)', category: 'Protein', kcal: 165, protein: 31, carbs: 0, fat: 3.6, servings: [FoodServing('1 portion (150g)', 150)]),
    FoodItem(name: 'Chicken Thigh', category: 'Protein', kcal: 209, protein: 26, carbs: 0, fat: 10.9),
    FoodItem(name: 'Fried Chicken (piece)', category: 'Protein', kcal: 290, protein: 22, carbs: 12, fat: 17, servings: [FoodServing('1 piece (120g)', 120)]),
    FoodItem(name: 'Beef, lean (cooked)', category: 'Protein', kcal: 250, protein: 26, carbs: 0, fat: 15),
    FoodItem(name: 'Pork Chop', category: 'Protein', kcal: 231, protein: 25, carbs: 0, fat: 14),
    FoodItem(name: 'Mutton (cooked)', category: 'Protein', kcal: 294, protein: 25, carbs: 0, fat: 21, servings: [FoodServing('1 portion (150g)', 150)]),
    FoodItem(name: 'Salmon', category: 'Protein', kcal: 208, protein: 20, carbs: 0, fat: 13, servings: [FoodServing('1 fillet (150g)', 150)]),
    FoodItem(name: 'Rohu Fish (cooked)', category: 'Protein', kcal: 145, protein: 21, carbs: 0, fat: 6, servings: [FoodServing('1 piece (100g)', 100)]),
    FoodItem(name: 'Tuna (canned, water)', category: 'Protein', kcal: 116, protein: 26, carbs: 0, fat: 0.8, servings: [FoodServing('1 can (100g)', 100)]),
    FoodItem(name: 'Sardines', category: 'Protein', kcal: 208, protein: 25, carbs: 0, fat: 11),
    FoodItem(name: 'Chicken Liver', category: 'Protein', kcal: 165, protein: 24, carbs: 1, fat: 6),
    FoodItem(name: 'Shrimp', category: 'Protein', kcal: 99, protein: 24, carbs: 0.2, fat: 0.3),
    FoodItem(name: 'Boiled Egg', category: 'Protein', kcal: 155, protein: 13, carbs: 1.1, fat: 11, servings: [FoodServing('1 boiled (50g)', 50), FoodServing('2 boiled (100g)', 100)]),
    FoodItem(name: 'Fried Egg', category: 'Protein', kcal: 196, protein: 13.6, carbs: 0.8, fat: 15, servings: [FoodServing('1 fried (46g)', 46)]),
    FoodItem(name: 'Omelette (2 egg)', category: 'Protein', kcal: 190, protein: 13, carbs: 1, fat: 15, servings: [FoodServing('1 omelette (120g)', 120)]),
    FoodItem(name: 'Egg Bhurji', category: 'Protein', kcal: 210, protein: 11, carbs: 4, fat: 16, servings: [FoodServing('1 plate (150g)', 150)]),
    FoodItem(name: 'Egg White', category: 'Protein', kcal: 52, protein: 11, carbs: 0.7, fat: 0.2),
    FoodItem(name: 'Whey Protein', category: 'Protein', kcal: 400, protein: 80, carbs: 8, fat: 6, servings: [FoodServing('1 scoop (30g)', 30)]),
    FoodItem(name: 'Greek Yogurt (0%)', category: 'Protein', kcal: 59, protein: 10, carbs: 3.6, fat: 0.4, servings: [FoodServing('1 cup (170g)', 170)]),
    FoodItem(name: 'Paneer', category: 'Protein', kcal: 265, protein: 18, carbs: 3.6, fat: 21, servings: [FoodServing('1 cube mix (100g)', 100)]),
    FoodItem(name: 'Cottage Cheese', category: 'Protein', kcal: 98, protein: 11, carbs: 3.4, fat: 4.3),
    FoodItem(name: 'Tofu', category: 'Protein', kcal: 76, protein: 8, carbs: 1.9, fat: 4.8),
    FoodItem(name: 'Soy Chunks', category: 'Protein', kcal: 345, protein: 52, carbs: 33, fat: 0.5, servings: [FoodServing('1 serving (50g)', 50)]),

    // ─── GRAINS ──────────────────────────────────────
    FoodItem(name: 'White Rice (cooked)', category: 'Grains', kcal: 130, protein: 2.7, carbs: 28, fat: 0.3, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Brown Rice (cooked)', category: 'Grains', kcal: 123, protein: 2.7, carbs: 26, fat: 1),
    FoodItem(name: 'Roti / Chapati', category: 'Grains', kcal: 297, protein: 8, carbs: 46, fat: 7.5, servings: [FoodServing('1 roti (40g)', 40), FoodServing('2 rotis (80g)', 80)]),
    FoodItem(name: 'Plain Paratha', category: 'Grains', kcal: 330, protein: 7, carbs: 42, fat: 13, servings: [FoodServing('1 paratha (80g)', 80)]),
    FoodItem(name: 'Aloo Paratha', category: 'Grains', kcal: 280, protein: 6, carbs: 38, fat: 10, servings: [FoodServing('1 paratha (100g)', 100)]),
    FoodItem(name: 'Naan', category: 'Grains', kcal: 310, protein: 9, carbs: 50, fat: 7, servings: [FoodServing('1 naan (90g)', 90)]),
    FoodItem(name: 'Puri', category: 'Grains', kcal: 280, protein: 6, carbs: 34, fat: 13, servings: [FoodServing('1 puri (25g)', 25)]),
    FoodItem(name: 'Bread, White', category: 'Grains', kcal: 265, protein: 9, carbs: 49, fat: 3.2, servings: [FoodServing('1 slice (30g)', 30)]),
    FoodItem(name: 'Bread, Whole Wheat', category: 'Grains', kcal: 247, protein: 13, carbs: 41, fat: 3.4, servings: [FoodServing('1 slice (32g)', 32)]),
    FoodItem(name: 'Oats (dry)', category: 'Grains', kcal: 389, protein: 16.9, carbs: 66, fat: 6.9, servings: [FoodServing('1 serving (40g)', 40)]),
    FoodItem(name: 'Muesli', category: 'Grains', kcal: 375, protein: 10, carbs: 66, fat: 8, servings: [FoodServing('1 bowl (50g)', 50)]),
    FoodItem(name: 'Corn Flakes', category: 'Grains', kcal: 357, protein: 7, carbs: 84, fat: 0.4, servings: [FoodServing('1 bowl (40g)', 40)]),
    FoodItem(name: 'Pasta (cooked)', category: 'Grains', kcal: 158, protein: 5.8, carbs: 31, fat: 0.9, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Potato (boiled)', category: 'Grains', kcal: 87, protein: 1.9, carbs: 20, fat: 0.1, servings: [FoodServing('1 medium (170g)', 170)]),
    FoodItem(name: 'Sweet Potato', category: 'Grains', kcal: 86, protein: 1.6, carbs: 20, fat: 0.1),
    FoodItem(name: 'Quinoa (cooked)', category: 'Grains', kcal: 120, protein: 4.4, carbs: 21, fat: 1.9),
    FoodItem(name: 'Poha', category: 'Grains', kcal: 130, protein: 2.6, carbs: 25, fat: 2.6, servings: [FoodServing('1 plate (150g)', 150)]),
    FoodItem(name: 'Upma', category: 'Grains', kcal: 132, protein: 3, carbs: 18, fat: 5, servings: [FoodServing('1 plate (200g)', 200)]),

    // ─── LEGUMES ─────────────────────────────────────
    FoodItem(name: 'Dal / Lentils (cooked)', category: 'Legumes', kcal: 116, protein: 9, carbs: 20, fat: 0.4, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Dal Makhani', category: 'Legumes', kcal: 150, protein: 7, carbs: 15, fat: 6, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Chickpeas (cooked)', category: 'Legumes', kcal: 164, protein: 8.9, carbs: 27, fat: 2.6),
    FoodItem(name: 'Chole (Chana Masala)', category: 'Legumes', kcal: 160, protein: 8, carbs: 22, fat: 4, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Kidney Beans (Rajma)', category: 'Legumes', kcal: 127, protein: 8.7, carbs: 22.8, fat: 0.5),
    FoodItem(name: 'Moong Sprouts (cooked)', category: 'Legumes', kcal: 105, protein: 7, carbs: 19, fat: 0.4, servings: [FoodServing('1 bowl (150g)', 150)]),

    // ─── FRUIT ───────────────────────────────────────
    FoodItem(name: 'Banana', category: 'Fruit', kcal: 89, protein: 1.1, carbs: 23, fat: 0.3, servings: [FoodServing('1 medium (118g)', 118)]),
    FoodItem(name: 'Apple', category: 'Fruit', kcal: 52, protein: 0.3, carbs: 14, fat: 0.2, servings: [FoodServing('1 medium (182g)', 182)]),
    FoodItem(name: 'Orange', category: 'Fruit', kcal: 47, protein: 0.9, carbs: 12, fat: 0.1, servings: [FoodServing('1 medium (130g)', 130)]),
    FoodItem(name: 'Mango', category: 'Fruit', kcal: 60, protein: 0.8, carbs: 15, fat: 0.4, servings: [FoodServing('1 cup (165g)', 165)]),
    FoodItem(name: 'Papaya', category: 'Fruit', kcal: 43, protein: 0.5, carbs: 11, fat: 0.3, servings: [FoodServing('1 cup (145g)', 145)]),
    FoodItem(name: 'Pomegranate', category: 'Fruit', kcal: 83, protein: 1.7, carbs: 19, fat: 1.2, servings: [FoodServing('1 cup (174g)', 174)]),
    FoodItem(name: 'Guava', category: 'Fruit', kcal: 68, protein: 2.6, carbs: 14, fat: 1, servings: [FoodServing('1 medium (55g)', 55)]),
    FoodItem(name: 'Pineapple', category: 'Fruit', kcal: 50, protein: 0.5, carbs: 13, fat: 0.1, servings: [FoodServing('1 cup (165g)', 165)]),
    FoodItem(name: 'Kiwi', category: 'Fruit', kcal: 61, protein: 1.1, carbs: 15, fat: 0.5, servings: [FoodServing('1 kiwi (75g)', 75)]),
    FoodItem(name: 'Dates', category: 'Fruit', kcal: 282, protein: 2.5, carbs: 75, fat: 0.4, servings: [FoodServing('2 dates (48g)', 48)]),
    FoodItem(name: 'Lychee', category: 'Fruit', kcal: 66, protein: 0.8, carbs: 17, fat: 0.4, servings: [FoodServing('5 lychees (75g)', 75)]),
    FoodItem(name: 'Grapes', category: 'Fruit', kcal: 69, protein: 0.7, carbs: 18, fat: 0.2),
    FoodItem(name: 'Strawberries', category: 'Fruit', kcal: 32, protein: 0.7, carbs: 7.7, fat: 0.3),
    FoodItem(name: 'Watermelon', category: 'Fruit', kcal: 30, protein: 0.6, carbs: 7.6, fat: 0.2),

    // ─── VEGGIES ─────────────────────────────────────
    FoodItem(name: 'Broccoli', category: 'Veggies', kcal: 34, protein: 2.8, carbs: 7, fat: 0.4),
    FoodItem(name: 'Spinach', category: 'Veggies', kcal: 23, protein: 2.9, carbs: 3.6, fat: 0.4),
    FoodItem(name: 'Carrot', category: 'Veggies', kcal: 41, protein: 0.9, carbs: 10, fat: 0.2, servings: [FoodServing('1 medium (60g)', 60)]),
    FoodItem(name: 'Tomato', category: 'Veggies', kcal: 18, protein: 0.9, carbs: 3.9, fat: 0.2),
    FoodItem(name: 'Cucumber', category: 'Veggies', kcal: 15, protein: 0.7, carbs: 3.6, fat: 0.1),
    FoodItem(name: 'Cauliflower', category: 'Veggies', kcal: 25, protein: 1.9, carbs: 5, fat: 0.3),
    FoodItem(name: 'Green Peas', category: 'Veggies', kcal: 81, protein: 5, carbs: 14, fat: 0.4, servings: [FoodServing('1 cup (150g)', 150)]),
    FoodItem(name: 'Sweet Corn', category: 'Veggies', kcal: 86, protein: 3.3, carbs: 19, fat: 1.4, servings: [FoodServing('1 cup (160g)', 160)]),
    FoodItem(name: 'Mushrooms', category: 'Veggies', kcal: 22, protein: 3.1, carbs: 3.3, fat: 0.3),
    FoodItem(name: 'Beetroot', category: 'Veggies', kcal: 43, protein: 1.6, carbs: 10, fat: 0.2),
    FoodItem(name: 'Okra (Bhindi)', category: 'Veggies', kcal: 33, protein: 1.9, carbs: 7, fat: 0.2, servings: [FoodServing('1 cup (100g)', 100)]),
    FoodItem(name: 'Brinjal (Eggplant)', category: 'Veggies', kcal: 25, protein: 1, carbs: 6, fat: 0.2),
    FoodItem(name: 'French Beans', category: 'Veggies', kcal: 31, protein: 1.8, carbs: 7, fat: 0.2),
    FoodItem(name: 'Capsicum (Bell Pepper)', category: 'Veggies', kcal: 20, protein: 0.9, carbs: 4.6, fat: 0.2),
    FoodItem(name: 'Mixed Salad', category: 'Veggies', kcal: 20, protein: 1.5, carbs: 3.5, fat: 0.2, servings: [FoodServing('1 bowl (100g)', 100)]),

    // ─── DAIRY ───────────────────────────────────────
    FoodItem(name: 'Milk, Whole', category: 'Dairy', kcal: 61, protein: 3.2, carbs: 4.8, fat: 3.3, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Milk, Skim', category: 'Dairy', kcal: 34, protein: 3.4, carbs: 5, fat: 0.1, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Cheese, Cheddar', category: 'Dairy', kcal: 403, protein: 25, carbs: 1.3, fat: 33, servings: [FoodServing('1 slice (20g)', 20)]),
    FoodItem(name: 'Cheese Slice (processed)', category: 'Dairy', kcal: 300, protein: 17, carbs: 3, fat: 24, servings: [FoodServing('1 slice (20g)', 20)]),
    FoodItem(name: 'Mozzarella', category: 'Dairy', kcal: 300, protein: 22, carbs: 2, fat: 22),
    FoodItem(name: 'Curd / Plain Yogurt', category: 'Dairy', kcal: 61, protein: 3.5, carbs: 4.7, fat: 3.3, servings: [FoodServing('1 bowl (150g)', 150)]),
    FoodItem(name: 'Lassi (sweet)', category: 'Dairy', kcal: 105, protein: 2.7, carbs: 17, fat: 2.5, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Buttermilk (Chaas)', category: 'Dairy', kcal: 20, protein: 1.5, carbs: 2.5, fat: 0.8, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Butter', category: 'Dairy', kcal: 717, protein: 0.9, carbs: 0.1, fat: 81, servings: [FoodServing('1 tbsp (14g)', 14)]),

    // ─── FATS & NUTS ─────────────────────────────────
    FoodItem(name: 'Almonds', category: 'Fats & Nuts', kcal: 579, protein: 21, carbs: 22, fat: 50, servings: [FoodServing('1 handful (28g)', 28)]),
    FoodItem(name: 'Peanuts', category: 'Fats & Nuts', kcal: 567, protein: 26, carbs: 16, fat: 49),
    FoodItem(name: 'Walnuts', category: 'Fats & Nuts', kcal: 654, protein: 15, carbs: 14, fat: 65),
    FoodItem(name: 'Peanut Butter', category: 'Fats & Nuts', kcal: 588, protein: 25, carbs: 20, fat: 50, servings: [FoodServing('1 tbsp (16g)', 16)]),
    FoodItem(name: 'Chia Seeds', category: 'Fats & Nuts', kcal: 486, protein: 17, carbs: 42, fat: 31, servings: [FoodServing('1 tbsp (12g)', 12)]),
    FoodItem(name: 'Flax Seeds', category: 'Fats & Nuts', kcal: 534, protein: 18, carbs: 29, fat: 42, servings: [FoodServing('1 tbsp (10g)', 10)]),
    FoodItem(name: 'Sunflower Seeds', category: 'Fats & Nuts', kcal: 584, protein: 21, carbs: 20, fat: 51, servings: [FoodServing('1 handful (28g)', 28)]),
    FoodItem(name: 'Olive Oil', category: 'Fats & Nuts', kcal: 884, protein: 0, carbs: 0, fat: 100, servings: [FoodServing('1 tbsp (14g)', 14)]),
    FoodItem(name: 'Coconut Oil', category: 'Fats & Nuts', kcal: 862, protein: 0, carbs: 0, fat: 100, servings: [FoodServing('1 tbsp (14g)', 14)]),
    FoodItem(name: 'Ghee', category: 'Fats & Nuts', kcal: 900, protein: 0, carbs: 0, fat: 100, servings: [FoodServing('1 tsp (5g)', 5)]),

    // ─── MEALS ───────────────────────────────────────
    FoodItem(name: 'Momos — Steamed Veg', category: 'Meals', kcal: 120, protein: 4, carbs: 18, fat: 2, servings: [FoodServing('6 pieces (150g)', 150)]),
    FoodItem(name: 'Momos — Steamed Chicken', category: 'Meals', kcal: 155, protein: 12, carbs: 16, fat: 4, servings: [FoodServing('6 pieces (150g)', 150)]),
    FoodItem(name: 'Momos — Fried', category: 'Meals', kcal: 250, protein: 6, carbs: 28, fat: 12, servings: [FoodServing('6 pieces (150g)', 150)]),
    FoodItem(name: 'Chicken Biryani', category: 'Meals', kcal: 190, protein: 8, carbs: 25, fat: 6, servings: [FoodServing('1 plate (300g)', 300)]),
    FoodItem(name: 'Rajma Chawal', category: 'Meals', kcal: 165, protein: 7, carbs: 27, fat: 3, servings: [FoodServing('1 plate (350g)', 350)]),
    FoodItem(name: 'Khichdi', category: 'Meals', kcal: 120, protein: 5, carbs: 18, fat: 2, servings: [FoodServing('1 bowl (250g)', 250)]),
    FoodItem(name: 'Curd Rice', category: 'Meals', kcal: 105, protein: 4, carbs: 16, fat: 2, servings: [FoodServing('1 bowl (250g)', 250)]),
    FoodItem(name: 'Butter Chicken', category: 'Meals', kcal: 235, protein: 17, carbs: 6, fat: 16, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Chicken Curry', category: 'Meals', kcal: 150, protein: 12, carbs: 5, fat: 9, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Palak Paneer', category: 'Meals', kcal: 180, protein: 9, carbs: 6, fat: 13, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Paneer Butter Masala', category: 'Meals', kcal: 240, protein: 10, carbs: 9, fat: 19, servings: [FoodServing('1 bowl (200g)', 200)]),
    FoodItem(name: 'Pizza', category: 'Meals', kcal: 266, protein: 11, carbs: 33, fat: 10, servings: [FoodServing('1 slice (100g)', 100)]),
    FoodItem(name: 'Burger', category: 'Meals', kcal: 295, protein: 17, carbs: 24, fat: 14, servings: [FoodServing('1 burger (200g)', 200)]),
    FoodItem(name: 'French Fries', category: 'Meals', kcal: 312, protein: 3.4, carbs: 41, fat: 15, servings: [FoodServing('medium (115g)', 115)]),
    FoodItem(name: 'Fried Rice', category: 'Meals', kcal: 163, protein: 5, carbs: 24, fat: 5, servings: [FoodServing('1 plate (250g)', 250)]),
    FoodItem(name: 'Hakka Noodles', category: 'Meals', kcal: 180, protein: 5, carbs: 28, fat: 5, servings: [FoodServing('1 plate (250g)', 250)]),
    FoodItem(name: 'Maggi Noodles', category: 'Meals', kcal: 400, protein: 9, carbs: 56, fat: 15, servings: [FoodServing('1 pack (70g)', 70)]),
    FoodItem(name: 'Idli', category: 'Meals', kcal: 130, protein: 4, carbs: 26, fat: 0.8, servings: [FoodServing('1 idli (40g)', 40)]),
    FoodItem(name: 'Idli + Sambar', category: 'Meals', kcal: 130, protein: 5, carbs: 20, fat: 3, servings: [FoodServing('3 idli + sambar (250g)', 250)]),
    FoodItem(name: 'Dosa (plain)', category: 'Meals', kcal: 168, protein: 4, carbs: 29, fat: 4, servings: [FoodServing('1 dosa (85g)', 85)]),
    FoodItem(name: 'Masala Dosa', category: 'Meals', kcal: 190, protein: 4, carbs: 28, fat: 7, servings: [FoodServing('1 dosa (120g)', 120)]),
    FoodItem(name: 'Uttapam', category: 'Meals', kcal: 150, protein: 5, carbs: 22, fat: 4, servings: [FoodServing('1 uttapam (120g)', 120)]),
    FoodItem(name: 'Samosa', category: 'Meals', kcal: 262, protein: 4.5, carbs: 26, fat: 14, servings: [FoodServing('1 samosa (60g)', 60)]),
    FoodItem(name: 'Vada Pav', category: 'Meals', kcal: 290, protein: 9, carbs: 38, fat: 11, servings: [FoodServing('1 vada pav (150g)', 150)]),
    FoodItem(name: 'Pav Bhaji', category: 'Meals', kcal: 130, protein: 3, carbs: 15, fat: 6, servings: [FoodServing('1 plate (300g)', 300)]),
    FoodItem(name: 'Pani Puri', category: 'Meals', kcal: 280, protein: 6, carbs: 40, fat: 10, servings: [FoodServing('6 pieces (120g)', 120)]),
    FoodItem(name: 'Bhel Puri', category: 'Meals', kcal: 330, protein: 7, carbs: 45, fat: 13, servings: [FoodServing('1 plate (150g)', 150)]),
    FoodItem(name: 'Dhokla', category: 'Meals', kcal: 160, protein: 7, carbs: 22, fat: 4, servings: [FoodServing('1 plate (150g)', 150)]),
    FoodItem(name: 'Pakora', category: 'Meals', kcal: 315, protein: 7, carbs: 30, fat: 18, servings: [FoodServing('1 bowl (100g)', 100)]),
    FoodItem(name: 'Egg Roll (Kathi)', category: 'Meals', kcal: 240, protein: 10, carbs: 28, fat: 10, servings: [FoodServing('1 roll (150g)', 150)]),
    FoodItem(name: 'Chicken Roll', category: 'Meals', kcal: 250, protein: 14, carbs: 26, fat: 9, servings: [FoodServing('1 roll (180g)', 180)]),
    FoodItem(name: 'Grilled Sandwich', category: 'Meals', kcal: 250, protein: 11, carbs: 28, fat: 10, servings: [FoodServing('1 sandwich (150g)', 150)]),
    FoodItem(name: 'Bhature', category: 'Meals', kcal: 350, protein: 7, carbs: 40, fat: 17, servings: [FoodServing('1 bhatura (80g)', 80)]),

    // ─── DRINKS ──────────────────────────────────────
    FoodItem(name: 'Black Coffee', category: 'Drinks', kcal: 2, protein: 0.1, carbs: 0, fat: 0, unit: 'ml', servings: [FoodServing('1 cup (240ml)', 240)]),
    FoodItem(name: 'Green Tea', category: 'Drinks', kcal: 1, protein: 0, carbs: 0.2, fat: 0, unit: 'ml', servings: [FoodServing('1 cup (240ml)', 240)]),
    FoodItem(name: 'Chai (milk + sugar)', category: 'Drinks', kcal: 45, protein: 1, carbs: 7, fat: 1.5, unit: 'ml', servings: [FoodServing('1 cup (150ml)', 150)]),
    FoodItem(name: 'Coconut Water', category: 'Drinks', kcal: 19, protein: 0.7, carbs: 3.7, fat: 0.2, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Lemon Water', category: 'Drinks', kcal: 8, protein: 0, carbs: 2, fat: 0, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Sugarcane Juice', category: 'Drinks', kcal: 65, protein: 0.2, carbs: 15, fat: 0.2, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Cola', category: 'Drinks', kcal: 42, protein: 0, carbs: 10.6, fat: 0, unit: 'ml', servings: [FoodServing('1 can (330ml)', 330)]),
    FoodItem(name: 'Diet Cola', category: 'Drinks', kcal: 0.4, protein: 0, carbs: 0.1, fat: 0, unit: 'ml', servings: [FoodServing('1 can (330ml)', 330)]),
    FoodItem(name: 'Orange Juice', category: 'Drinks', kcal: 45, protein: 0.7, carbs: 10.4, fat: 0.2, unit: 'ml', servings: [FoodServing('1 glass (250ml)', 250)]),
    FoodItem(name: 'Chocolate Milkshake', category: 'Drinks', kcal: 90, protein: 3, carbs: 14, fat: 2.5, unit: 'ml', servings: [FoodServing('1 glass (300ml)', 300)]),
    FoodItem(name: 'Beer', category: 'Drinks', kcal: 43, protein: 0.5, carbs: 3.6, fat: 0, unit: 'ml', servings: [FoodServing('1 bottle (330ml)', 330)]),
    FoodItem(name: 'Protein Shake (whey + water)', category: 'Drinks', kcal: 40, protein: 8.7, carbs: 1.1, fat: 0.5, unit: 'ml', servings: [FoodServing('1 shake (300ml)', 300)]),

    // ─── SNACKS ──────────────────────────────────────
    FoodItem(name: 'Dark Chocolate', category: 'Snacks', kcal: 546, protein: 5, carbs: 61, fat: 31, servings: [FoodServing('2 squares (20g)', 20)]),
    FoodItem(name: 'Milk Chocolate', category: 'Snacks', kcal: 535, protein: 7.6, carbs: 59, fat: 30),
    FoodItem(name: 'Potato Chips', category: 'Snacks', kcal: 536, protein: 7, carbs: 53, fat: 34, servings: [FoodServing('small pack (30g)', 30)]),
    FoodItem(name: 'Biscuits', category: 'Snacks', kcal: 480, protein: 6, carbs: 65, fat: 20, servings: [FoodServing('2 biscuits (20g)', 20)]),
    FoodItem(name: 'Ice Cream', category: 'Snacks', kcal: 207, protein: 3.5, carbs: 24, fat: 11, servings: [FoodServing('1 scoop (65g)', 65)]),
    FoodItem(name: 'Protein Bar', category: 'Snacks', kcal: 350, protein: 30, carbs: 35, fat: 10, servings: [FoodServing('1 bar (60g)', 60)]),
    FoodItem(name: 'Granola Bar', category: 'Snacks', kcal: 471, protein: 10, carbs: 64, fat: 20, servings: [FoodServing('1 bar (40g)', 40)]),
    FoodItem(name: 'Makhana (roasted)', category: 'Snacks', kcal: 347, protein: 10, carbs: 70, fat: 2, servings: [FoodServing('1 bowl (30g)', 30)]),
    FoodItem(name: 'Popcorn (plain)', category: 'Snacks', kcal: 387, protein: 13, carbs: 78, fat: 4.5, servings: [FoodServing('1 bowl (30g)', 30)]),
    FoodItem(name: 'Peanut Chikki', category: 'Snacks', kcal: 470, protein: 13, carbs: 62, fat: 19, servings: [FoodServing('1 piece (25g)', 25)]),
    FoodItem(name: 'Khakhra', category: 'Snacks', kcal: 500, protein: 10, carbs: 65, fat: 20, servings: [FoodServing('1 khakhra (15g)', 15)]),
    FoodItem(name: 'Thepla', category: 'Snacks', kcal: 350, protein: 7, carbs: 45, fat: 15, servings: [FoodServing('1 thepla (40g)', 40)]),
    FoodItem(name: 'Cake (plain)', category: 'Snacks', kcal: 350, protein: 5, carbs: 50, fat: 15, servings: [FoodServing('1 slice (80g)', 80)]),
    FoodItem(name: 'Donut', category: 'Snacks', kcal: 452, protein: 5, carbs: 51, fat: 25, servings: [FoodServing('1 donut (60g)', 60)]),
    FoodItem(name: 'Muffin', category: 'Snacks', kcal: 377, protein: 5, carbs: 54, fat: 16, servings: [FoodServing('1 muffin (110g)', 110)]),
    FoodItem(name: 'Indian Sweets (Mithai)', category: 'Snacks', kcal: 400, protein: 4, carbs: 50, fat: 20, servings: [FoodServing('1 piece (50g)', 50)]),
  ];
}