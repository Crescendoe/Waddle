import 'package:flutter/material.dart';

class DrinkSelectionBottomSheet extends StatelessWidget {
  final Function(String, double) onDrinkSelected;
  final int? activeChallengeIndex;
  final Key? key;
  DrinkSelectionBottomSheet({
    this.key,
    required this.onDrinkSelected,
    this.activeChallengeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 475,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'What did you drink?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3, // Number of columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 2,
              children: _buildDrinkItems(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrinkItems(BuildContext context) {
    final drinks = [
      // Waters
      {
        'name': 'Water',
        'icon': Icons.water,
        'ratio': 1.0,
        'color': Colors.blue
      },
      {
        'name': 'Sparkling Water',
        'icon': Icons.bubble_chart,
        'ratio': 1.0,
        'color': Colors.lightBlue
      },
      {
        'name': 'Coconut Water',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.brown
      },
      // Teas
      {
        'name': 'Black Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.black
      },
      {
        'name': 'Green Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.green
      },
      {
        'name': 'Herbal Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.lightGreen
      },
      {
        'name': 'Matcha',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.greenAccent
      },
      // Juices
      {
        'name': 'Juice',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.orange
      },
      {
        'name': 'Lemonade',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.yellow
      },
      // Milks
      {
        'name': 'Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      {
        'name': 'Skim Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.grey[300],
      },
      {
        'name': 'Almond Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.pink[100]
      },
      {
        'name': 'Oat Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.brown[100]
      },
      {
        'name': 'Soy Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.grey[200]
      },
      // Yogurt
      {
        'name': 'Yogurt',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.orangeAccent
      },
      // Milkshake
      {
        'name': 'Milkshake',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.purple
      },
      // Energy Drinks
      {
        'name': 'Energy Drink',
        'icon': Icons.flash_on,
        'ratio': 0.6,
        'color': Colors.red
      },
      // Coffee
      {
        'name': 'Coffee',
        'icon': Icons.coffee,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Decaf Coffee',
        'icon': Icons.coffee,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Latte',
        'icon': Icons.local_cafe,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Hot Chocolate',
        'icon': Icons.local_cafe,
        'ratio': 0.5,
        'color': Colors.brown
      },
      // Sodas
      {
        'name': 'Soda',
        'icon': Icons.local_drink,
        'ratio': 0.4,
        'color': Colors.brown
      },
      {
        'name': 'Diet Soda',
        'icon': Icons.local_drink,
        'ratio': 0.4,
        'color': Colors.brown
      },
      // Smoothies
      {
        'name': 'Smoothie',
        'icon': Icons.blender,
        'ratio': 0.8,
        'color': Colors.purple
      },
      // Sports Drinks
      {
        'name': 'Sports Drink',
        'icon': Icons.sports,
        'ratio': 0.8,
        'color': Colors.blue
      },
      {
        'name': 'Protein Shake',
        'icon': Icons.fitness_center,
        'ratio': 0.8,
        'color': Colors.orangeAccent
      },
      // Soup
      {
        'name': 'Soup',
        'icon': Icons.soup_kitchen,
        'ratio': 0.6,
        'color': Colors.redAccent
      },
    ];

    // Filter drinks based on active challenge
    List<Map<String, dynamic>> filteredDrinks = drinks;
    if (activeChallengeIndex == 0) {
      filteredDrinks = drinks.where((drink) {
        return drink['name'] == 'Water' ||
            drink['name'] == 'Sparkling Water' ||
            drink['name'] == 'Coconut Water';
      }).toList();
    }

    return filteredDrinks.map((drink) {
      return GestureDetector(
        onTap: () {
          onDrinkSelected(drink['name'] as String, drink['ratio'] as double);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(drink['icon'] as IconData,
                size: 55, color: drink['color'] as Color),
            const SizedBox(height: 5),
            Text(
              drink['name'] as String,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
