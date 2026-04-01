import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/database/exit_dao.dart';
import 'package:shop/database/product_dao.dart';
import 'package:shop/database/expense_dao.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBarIndex = -1;

  // Real metrics
  double todaySales = 0.0;
  double monthlySales = 0.0;
  double totalExpenses = 0.0;
  String topSellingProduct = "---";
  int outOfStockCount = 0;
  bool isLoading = true;

  final ExitDao _exitDao = ExitDao();
  final ProductDao _productDao = ProductDao();
  final ExpenseDao _expenseDao = ExpenseDao();

  // Custom colors
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color primaryYellow = const Color(0xFFFACC15);
  final Color accentRed = const Color(0xFFEF4444);
  final Color primaryOrange = const Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => isLoading = true);
    try {
      final today = await _exitDao.getTodaySales();
      final month = await _exitDao.getMonthlySales();
      final expenses = await _expenseDao.getMonthlyExpenses();
      final topProduct = await _exitDao.getTopSellingProduct();
      final outOfStock = await _productDao.getOutOfStockCount();

      if (mounted) {
        setState(() {
          todaySales = today;
          monthlySales = month;
          totalExpenses = expenses;
          topSellingProduct = topProduct != null ? topProduct['name'] : "Aucun";
          outOfStockCount = outOfStock;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading sales data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSalesData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopCards(),
                const SizedBox(height: defaultPadding),

                _cardWrapper(
                  "Activité",
                  300,
                  _buildBarChart(),
                  subtitle: "Ventes et dépenses",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                "Top des ventes",
                topSellingProduct,
                Icons.trending_up,
                successColor,
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: _metricCard(
                "Ruptures",
                outOfStockCount.toString(),
                Icons.warning_amber_rounded,
                warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _metricCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: value.length > 10 ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  Widget _cardWrapper(String title, double height, Widget child, {String? subtitle}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: primaryYellow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: darkBlue.withOpacity(0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.insights_rounded,
                color: Colors.black54,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          // 🔥 GRAPH
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxYValue =
        (monthlySales > totalExpenses ? monthlySales : totalExpenses);
    final axisMax = maxYValue > 0 ? maxYValue * 1.4 : 100.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: axisMax,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.spot != null) {
              final index = response!.spot!.touchedBarGroupIndex;
              setState(() => _selectedBarIndex = index);
              _executeBarAction(index);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormat.compact().format(rod.toY),
                TextStyle(
                  color: darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        barGroups: [
          _makeGroup(0, todaySales, darkBlue,
              _selectedBarIndex == 0, axisMax),
          _makeGroup(1, monthlySales, primaryYellow,
              _selectedBarIndex == 1, axisMax),
          _makeGroup(2, totalExpenses, accentRed,
              _selectedBarIndex == 2, axisMax),
        ],
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, meta) {
                const titles = ['Vte Jour', 'Vte Mois', 'Dépenses'];
                const icons = [
                  Icons.today,
                  Icons.calendar_view_month,
                  Icons.account_balance_wallet
                ];

                final idx = value.toInt();
                if (idx >= titles.length) return const SizedBox();

                final isSelected = _selectedBarIndex == idx;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedBarIndex = idx);
                    _executeBarAction(idx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? darkBlue : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected ? darkBlue : Colors.grey[300]!,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: darkBlue.withOpacity(0.2),
                                        blurRadius: 5)
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[idx],
                                size: 12,
                                color: isSelected
                                    ? primaryYellow
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                titles[idx],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          idx == 0
                              ? NumberFormat.compact().format(todaySales)
                              : idx == 1
                                  ? NumberFormat.compact().format(monthlySales)
                                  : NumberFormat.compact().format(totalExpenses),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? darkBlue
                                : darkBlue.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  BarChartGroupData _makeGroup(
      int x, double y, Color color, bool isTouched, double axisMax) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isTouched ? color : color.withOpacity(0.7),
          width: isTouched ? 22 : 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: axisMax,
            color: isTouched ? color.withOpacity(0.05) : const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  void _executeBarAction(int index) {
    if (index == 0 || index == 1) {
      // In mobile, we just navigate to the Receipts or show a message
      // If we are in EntryPoint, we might want to switch tabs
    } else if (index == 2) {
      // Logic for expenses if needed
    }
  }
}