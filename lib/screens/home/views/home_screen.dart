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
    return Row(
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
            "Stock en rupture",
            outOfStockCount.toString(),
            Icons.warning_amber_rounded,
            warningColor,
          ),
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
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color:Colors.grey[300]!,),),
      child: Column(
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],

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
          _makeGroup(1, monthlySales, primaryOrange,
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
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                const titles = ['Jour', 'Mois', 'Dépenses'];
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                         color: isSelected ? darkBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected ? darkBlue : Colors.grey[300]!,
                        ),
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
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
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: axisMax,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  void _executeBarAction(int index) {
    debugPrint("Bar $index tapped");
  }
}