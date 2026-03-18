class CategoryModel {
  String name; // ✅ ADD THIS
  String vector;
  bool isSelected;

  CategoryModel({
    required this.name, // ✅ ADD THIS
    required this.vector,
    required this.isSelected,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
        name: 'Cardiology', // ✅ ADD NAME
        vector: 'assets/vectors/heart.svg',
        isSelected: false,
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Medicine',
        vector: 'assets/vectors/pil.svg',
        isSelected: false,
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Dentist',
        vector: 'assets/vectors/dentist.svg',
        isSelected: true,
      ),
    );

    return categories;
  }
}
