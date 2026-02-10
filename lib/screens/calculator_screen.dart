import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/bju_record.dart';
import '../main.dart' as main_app;

class CalculatorScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CalculatorScreen({super.key, this.initialDate});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Product> _products = [];
  Product? _selectedProduct;
  final TextEditingController _gramsController = TextEditingController();
  Map<String, dynamic>? _calculatedBJU;
  bool _isLoading = true;
  String? _errorMessage;
  late DateTime _selectedDate;
  String _selectedMealType = 'Snack';
  DateTime? _lastGlobalDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _lastGlobalDate = main_app.selectedDateForCalculation;
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lastGlobalDate != main_app.selectedDateForCalculation) {
      setState(() {
        _selectedDate = main_app.selectedDateForCalculation;
        _lastGlobalDate = main_app.selectedDateForCalculation;
      });
    }
  }

  Future<void> _loadProducts() async {
    print('[CalculatorScreen] Initializing _loadProducts()...');

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('[CalculatorScreen] Fetching products from database...');
      final products = await _dbHelper.getAllProducts();
      print('[CalculatorScreen] Products fetched: ${products.length} items');

      if (mounted) {
        setState(() {
          _products = products;
        });
      }
    } catch (e, stackTrace) {
      print('[CalculatorScreen] ERROR during _loadProducts(): $e');
      print('[CalculatorScreen] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load products. Please restart the app.';
        });
      }
    } finally {
      print(
          '[CalculatorScreen] _loadProducts() completed, setting _isLoading = false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateBJU() {
    if (_selectedProduct == null || _gramsController.text.isEmpty) return;

    final grams = double.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) return;

    setState(() {
      _calculatedBJU = _selectedProduct!.calculateBJU(grams);
    });
  }

  Future<void> _saveCalculation() async {
    if (_calculatedBJU == null || _selectedProduct == null) return;

    // Validate that the selected date is not in the future
    if (_selectedDate.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('You cannot record a meal for a future date'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    try {
      final record = BjuRecord(
        productId: _selectedProduct!.id!,
        productName: _selectedProduct!.name,
        grams: _calculatedBJU!['grams'],
        protein: double.parse(_calculatedBJU!['protein']),
        fat: double.parse(_calculatedBJU!['fat']),
        carbs: double.parse(_calculatedBJU!['carbs']),
        calories: double.parse(_calculatedBJU!['calories']),
        dateTime: _selectedDate,
        mealType: _selectedMealType,
      );

      await _dbHelper.insertBjuRecord(record);

      // Reset UI state after successful save
      setState(() {
        _gramsController.clear();
        _selectedProduct = null;
        _calculatedBJU = null;
        _selectedDate = DateTime.now();
        _selectedMealType = 'Snack';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Calculation saved successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CalculatorScreen] Error saving calculation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Failed to save calculation. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧮 ', style: TextStyle(fontSize: 24)),
            Text('BJU Calculator'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProductSelector(),
          const SizedBox(height: 24),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildMealTypeSelector(),
          const SizedBox(height: 24),
          _buildGramsInput(),
          const SizedBox(height: 24),
          if (_selectedProduct != null) ...[
            _buildProductInfoCard(),
            const SizedBox(height: 24),
          ],
          if (_calculatedBJU != null) _buildResultsCard(),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    print(
        '[CalculatorScreen] Building product selector - products count: ${_products.length}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Select Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Product>(
            initialValue: _products.isEmpty ? null : _selectedProduct,
            isExpanded: true,
            isDense: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: _products.isEmpty
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFF3A3A3A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: const Color(0xFF3A3A3A),
            style: TextStyle(
                color: _products.isEmpty ? Colors.grey : Colors.white,
                fontSize: 16),
            hint: Text(
              _products.isEmpty
                  ? 'No products available - Add products first'
                  : 'Choose a product...',
              style: TextStyle(
                  color: _products.isEmpty
                      ? Colors.orange
                      : const Color(0xFF9E9E9E)),
            ),
            icon: Icon(Icons.arrow_drop_down,
                color:
                    _products.isEmpty ? Colors.grey : const Color(0xFF4CAF50)),
            items: _products.isEmpty
                ? [
                    DropdownMenuItem<Product>(
                      enabled: false,
                      value: null,
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No products available. Please add products in the Products section.',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                : _products.map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Row(
                        children: [
                          Text(product.emoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              product.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            onChanged: _products.isEmpty
                ? null
                : (product) {
                    print(
                        '[CalculatorScreen] Product selected: ${product?.name}');
                    setState(() {
                      _selectedProduct = product;
                      _calculatedBJU = null;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Select Date and Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF4CAF50),
                              onPrimary: Colors.white,
                              surface: Color(0xFF2A2A2A),
                              onSurface: Colors.white,
                            ),
                            dialogTheme: const DialogThemeData(
                                backgroundColor: Color(0xFF1A1A1A)),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF9E9E9E),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDate),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF4CAF50),
                              onPrimary: Colors.white,
                              surface: Color(0xFF2A2A2A),
                              onSurface: Colors.white,
                            ),
                            dialogTheme: const DialogThemeData(
                                backgroundColor: Color(0xFF1A1A1A)),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF4CAF50),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('HH:mm').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF9E9E9E),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    final mealTypes = [
      {'name': 'Breakfast', 'emoji': '🍳'},
      {'name': 'Lunch', 'emoji': '🍱'},
      {'name': 'Dinner', 'emoji': '🍽️'},
      {'name': 'Snack', 'emoji': '🍎'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Meal Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: mealTypes.map((meal) {
              final isSelected = _selectedMealType == meal['name'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedMealType = meal['name'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4CAF50).withOpacity(0.2)
                        : const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: meal['name'] as String,
                        groupValue: _selectedMealType,
                        onChanged: (value) {
                          setState(() {
                            _selectedMealType = value!;
                          });
                        },
                        activeColor: const Color(0xFF4CAF50),
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF4CAF50);
                            }
                            return Colors.grey;
                          },
                        ),
                      ),
                      Text(
                        meal['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        meal['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGramsInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.scale_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Enter Weight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _gramsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF3A3A3A),
                    hintText: '100',
                    hintStyle: const TextStyle(color: Color(0xFF757575)),
                    suffixText: 'g',
                    suffixStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF4CAF50), width: 2),
                    ),
                  ),
                  onChanged: (_) => _calculateBJU(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _selectedProduct == null ? null : _calculateBJU,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Calc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Per 100g',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 16,
                alignment: WrapAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    label: 'Protein',
                    value: '${_selectedProduct!.protein}g',
                    color: const Color(0xFFEF5350),
                    icon: Icons.fitness_center_rounded,
                  ),
                  _buildInfoItem(
                    label: 'Fat',
                    value: '${_selectedProduct!.fat}g',
                    color: const Color(0xFFFFB74D),
                    icon: Icons.opacity_rounded,
                  ),
                  _buildInfoItem(
                    label: 'Carbs',
                    value: '${_selectedProduct!.carbs}g',
                    color: const Color(0xFF42A5F5),
                    icon: Icons.grain_rounded,
                  ),
                  _buildInfoItem(
                    label: 'Calories',
                    value: '${_selectedProduct!.calories}',
                    color: const Color(0xFF66BB6A),
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_calculatedBJU!['grams'].toStringAsFixed(0)}g ${_selectedProduct!.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: constraints.maxWidth < 300 ? 8 : 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceEvenly,
                children: [
                  _buildResultItem(
                    label: 'Protein',
                    value: '${_calculatedBJU!['protein']}g',
                    emoji: '🥩',
                  ),
                  _buildResultItem(
                    label: 'Fat',
                    value: '${_calculatedBJU!['fat']}g',
                    emoji: '🥑',
                  ),
                  _buildResultItem(
                    label: 'Carbs',
                    value: '${_calculatedBJU!['carbs']}g',
                    emoji: '🍞',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_calculatedBJU!['calories']} kcal',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_selectedProduct != null && _gramsController.text.isNotEmpty)
                      ? _saveCalculation
                      : null,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Calculation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4CAF50),
                disabledBackgroundColor: Colors.white.withOpacity(0.3),
                disabledForegroundColor: Colors.white.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required String label,
    required String value,
    required String emoji,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }
}
