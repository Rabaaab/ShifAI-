/// General food and activity guidance for lowering the risk of type 2 diabetes.
/// Not a personal diet or exercise prescription: a doctor or dietitian adapts
/// it to the person.
library;

import '../l10n/l10n.dart';

enum FoodLevel { go, watch, limit }

extension FoodLevelX on FoodLevel {
  String get label {
    switch (this) {
      case FoodLevel.go:
        return 'Choose often'.tr;
      case FoodLevel.watch:
        return 'Watch the portion'.tr;
      case FoodLevel.limit:
        return 'Keep small'.tr;
    }
  }
}

class FoodItem {
  final String name;
  final String examples;
  final FoodLevel level;
  final String advice;

  /// Photo of the food, bundled under assets/images/food/.
  final String image;
  const FoodItem({
    required this.name,
    required this.image,
    required this.examples,
    required this.level,
    required this.advice,
  });
}

/// Moroccan food, grouped by how strongly it raises blood sugar for a normal
/// portion. Qualitative on purpose: exact glycemic numbers change with the
/// recipe, the portion and what is eaten alongside.
const foodItems = <FoodItem>[
  FoodItem(
    name: 'Lentils, chickpeas, beans',
    image: 'assets/images/food/legumes.jpg',
    examples: 'adess, hommos, lobia, harira legumes',
    level: FoodLevel.go,
    advice:
        'Slow carbohydrates with fibre and protein. Add them to soups, '
        'tagines and salads.',
  ),
  FoodItem(
    name: 'Vegetables and cooked salads',
    image: 'assets/images/food/vegetables.jpg',
    examples: 'zaalouk, taktouka, carrots, courgettes, tomato salad',
    level: FoodLevel.go,
    advice:
        'Fill half of your plate. Cook with olive oil and spices, not extra '
        'sugar.',
  ),
  FoodItem(
    name: 'Fish, eggs, chicken, lean meat',
    image: 'assets/images/food/fish_eggs_chicken.jpg',
    examples: 'sardines, grilled fish, eggs, chicken tagine',
    level: FoodLevel.go,
    advice:
        'Protein keeps you full for longer. Prefer grilled, steamed or '
        'slow-cooked over fried.',
  ),
  FoodItem(
    name: 'Plain yogurt and lben',
    image: 'assets/images/food/yogurt.jpg',
    examples: 'unsweetened yogurt, lben, raib',
    level: FoodLevel.go,
    advice: 'Choose the unsweetened kind and add fruit yourself.',
  ),
  FoodItem(
    name: 'Whole fruit',
    image: 'assets/images/food/whole_fruit.jpg',
    examples: 'orange, apple, pear, strawberries',
    level: FoodLevel.go,
    advice:
        'Whole fruit has fibre that slows sugar. Choose it instead of juice.',
  ),
  FoodItem(
    name: 'Nuts and olives',
    image: 'assets/images/food/nuts_olives.jpg',
    examples: 'almonds, walnuts, olives',
    level: FoodLevel.go,
    advice: 'A small handful is enough. They are good with dates or tea.',
  ),
  FoodItem(
    name: 'Harira',
    image: 'assets/images/food/harira.jpg',
    examples: 'harira soup',
    level: FoodLevel.watch,
    advice:
        'Legumes make it filling. Watch the bread, dates and sweets that '
        'come with it.',
  ),
  FoodItem(
    name: 'Whole-wheat bread, barley, whole semolina',
    image: 'assets/images/food/whole_bread.jpg',
    examples: 'khobz complet, belboula, shaïr',
    level: FoodLevel.watch,
    advice: 'Better than white. Keep to one portion about the size of a fist.',
  ),
  FoodItem(
    name: 'Couscous, rice, pasta',
    image: 'assets/images/food/couscous.jpg',
    examples: 'Friday couscous, white rice, vermicelli',
    level: FoodLevel.watch,
    advice:
        'Let vegetables take half the plate and couscous a quarter. Barley or '
        'whole semolina couscous is a better choice.',
  ),
  FoodItem(
    name: 'Tagine with potatoes or dried fruit',
    image: 'assets/images/food/tagine.jpg',
    examples: 'lamb with prunes, potato tagine',
    level: FoodLevel.watch,
    advice:
        'Add more vegetables, use fewer potatoes and keep dried fruit to a '
        'few pieces.',
  ),
  FoodItem(
    name: 'Dates, figs, dried fruit',
    image: 'assets/images/food/dates.jpg',
    examples: 'dates, figs, raisins',
    level: FoodLevel.watch,
    advice:
        'Natural, but very sugary. One or two dates with a few almonds, not a '
        'bowl.',
  ),
  FoodItem(
    name: 'White bread and fried dough',
    image: 'assets/images/food/white_bread_fried.jpg',
    examples: 'khobz, msemen, baghrir, harcha, fries',
    level: FoodLevel.limit,
    advice:
        'Fast carbohydrates. Halve the portion and add eggs, beans or '
        'vegetables, or switch to whole-wheat or barley bread.',
  ),
  FoodItem(
    name: 'Sugar in tea and coffee',
    image: 'assets/images/food/sweet_tea.jpg',
    examples: 'sweet mint tea, café au lait with sugar',
    level: FoodLevel.limit,
    advice:
        'Cut sugar step by step: half, then a quarter, then none. Plain mint '
        'tea is a good drink.',
  ),
  FoodItem(
    name: 'Soda and packaged juice',
    image: 'assets/images/food/soda.jpg',
    examples: 'soft drinks, fruit nectar, energy drinks',
    level: FoodLevel.limit,
    advice: 'Drink water, plain mint tea or sparkling water instead.',
  ),
  FoodItem(
    name: 'Pastries and sweets',
    image: 'assets/images/food/pastries.jpg',
    examples: 'chebakia, sellou, gazelle horns, cakes',
    level: FoodLevel.limit,
    advice:
        'Keep them for special days. A small piece straight after a meal is '
        'gentler than a snack on its own.',
  ),
];

class Exercise {
  final String title;
  final String detail;

  /// Picture of the exercise, bundled under assets/images/exercise/.
  final String image;
  const Exercise(this.title, this.detail, this.image);
}

const aerobicIdeas = <Exercise>[
  Exercise(
    'Brisk walk',
    'You can talk but not sing. The easiest place to start.',
    'assets/images/exercise/walk.jpg',
  ),
  Exercise(
    'Cycling or swimming',
    'Gentle on the joints, good for longer sessions.',
    'assets/images/exercise/cycling.jpg',
  ),
  Exercise(
    'Football, dancing, stairs',
    'Anything that raises your breathing counts.',
    'assets/images/exercise/football.jpg',
  ),
];

const strengthIdeas = <Exercise>[
  Exercise(
    'Squats to a chair',
    '2 sets of 8 to 12. Muscle uses blood sugar.',
    'assets/images/exercise/squat.png',
  ),
  Exercise(
    'Wall or knee push-ups',
    '2 sets of 8 to 12, at your own pace.',
    'assets/images/exercise/pushup.jpg',
  ),
  Exercise(
    'Resistance band rows',
    '2 sets of 10 to 12 with a band or water bottles.',
    'assets/images/exercise/band.jpg',
  ),
];

/// Weekly activity target (minutes of moderate activity): the WHO advises 150
/// to 300 minutes a week for adults.
const weeklyGoalMinutes = 150;
