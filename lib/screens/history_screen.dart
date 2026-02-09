import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/bju_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<BjuRecord> _records = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh records when navigating back to this tab
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await _dbHelper.getAllBjuRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(BjuRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Record?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && record.id != null) {
      await _dbHelper.deleteBjuRecord(record.id!);
      await _loadRecords();
    }
  }

  Map<String, List<BjuRecord>> _groupRecordsByDate() {
    final grouped = <String, List<BjuRecord>>{};
    for (var record in _records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.dateTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  Map<String, dynamic> _calculateDailyTotals(List<BjuRecord> dayRecords) {
    double protein = 0, fat = 0, carbs = 0, calories = 0;
    for (var record in dayRecords) {
      protein += record.protein;
      fat += record.fat;
      carbs += record.carbs;
      calories += record.calories;
    }
    return {
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'calories': calories,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊 ', style: TextStyle(fontSize: 24)),
            Text('History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF4CAF50)),
            onPressed: () async {
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
                setState(() => _selectedDate = date);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_records.isEmpty) {
      return _buildEmptyState();
    }
    return _buildHistoryList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '📋',
              style: TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start calculating BJU values\nand they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/calculator');
            },
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Calculate Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final grouped = _groupRecordsByDate();
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Filter to show only the selected date
    if (!grouped.containsKey(selectedDateKey)) {
      return _buildEmptyStateForDate();
    }

    final dayRecords = grouped[selectedDateKey]!;
    final totals = _calculateDailyTotals(dayRecords);
    final isToday =
        DateFormat('yyyy-MM-dd').format(DateTime.now()) == selectedDateKey;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateHeader(_selectedDate, isToday, totals),
        const SizedBox(height: 12),
        ...dayRecords.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildEmptyStateForDate() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '📅',
              style: TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Records for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Try selecting a different date\nor add new calculations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            icon: const Icon(Icons.today),
            label: const Text('Go to Today'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(
    DateTime date,
    bool isToday,
    Map<String, dynamic> totals,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.3),
            const Color(0xFF2E7D32).withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF4CAF50),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${totals['calories'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const Text(
                      ' kcal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDailyMacro(
                  '🥩', '${totals['protein'].toStringAsFixed(1)}g', 'Protein'),
              _buildDailyMacro(
                  '🥑', '${totals['fat'].toStringAsFixed(1)}g', 'Fat'),
              _buildDailyMacro(
                  '🍞', '${totals['carbs'].toStringAsFixed(1)}g', 'Carbs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMacro(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BjuRecord record) {
    return Dismissible(
      key: Key(record.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteRecord(record),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⚖️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '${record.grams.toStringAsFixed(0)}g',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroValue(
                    '${record.protein.toStringAsFixed(1)}g',
                    'Protein',
                    const Color(0xFFEF5350),
                  ),
                  _buildMacroValue(
                    '${record.fat.toStringAsFixed(1)}g',
                    'Fat',
                    const Color(0xFFFFB74D),
                  ),
                  _buildMacroValue(
                    '${record.carbs.toStringAsFixed(1)}g',
                    'Carbs',
                    const Color(0xFF42A5F5),
                  ),
                  _buildMacroValue(
                    record.calories.toStringAsFixed(0),
                    'kcal',
                    const Color(0xFF66BB6A),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('HH:mm').format(record.dateTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroValue(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
