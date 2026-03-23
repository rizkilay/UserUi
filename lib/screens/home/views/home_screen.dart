import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBarIndex = -1;

  // Demo metrics
  final double todaySales = 2500.0;
  final double monthlySales = 45000.0;
  final double totalExpenses = 12000.0;

  // Custom colors
  final Color darkBlue = const Color(0xFF1E3A8A);
  final Color primaryYellow = const Color(0xFFFACC15);
  final Color accentRed = const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
    );
  }

  Widget _buildTopCards() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            "Top des ventes",
            "128",
            Icons.trending_up,
            successColor,
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: _metricCard(
            "Stock en rupture",
            "5",
            Icons.warning_amber_rounded,
            warningColor,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 CARD AVEC TITRE + SOUS-TITRE CENTRÉS
  Widget _cardWrapper(String title, double height, Widget child, {String? subtitle}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🔥 TITRE CENTRÉ
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // 🔥 SOUS-TITRE CENTRÉ
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
          width: 16,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: axisMax,
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }

  void _executeBarAction(int index) {
    debugPrint("Bar $index tapped");
  }
}