import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/database/exit_dao.dart';
import 'package:shop/database/product_dao.dart';
import 'package:shop/database/expense_dao.dart';
import 'package:shop/models/product_model.dart';

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
  double yearlySales = 0.0;
  double totalExpenses = 0.0;
  int distinctProductsSold = 0;
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
      final year = await _exitDao.getYearlySales();
      final expenses = await _expenseDao.getMonthlyExpenses();
      final distinctProducts = await _exitDao.getDistinctProductsSold();
      final outOfStock = await _productDao.getOutOfStockCount();

      if (mounted) {
        setState(() {
          todaySales = today;
          monthlySales = month;
          yearlySales = year;
          totalExpenses = expenses;
          distinctProductsSold = distinctProducts;
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
                  subtitle: "Période des ventes",
                ),
                const SizedBox(height: defaultPadding),
                _metricCard(
                  "Dépenses ce mois",
                  "${NumberFormat.compact().format(totalExpenses)} XOF",
                  Icons.account_balance_wallet,
                  accentRed,
                  isBlueGradient: true,
                  
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
                "Articles vendus",
                distinctProductsSold.toString(),
                Icons.inventory_2,
                successColor,
                onTap: () => _showSoldProductsModal(context),
              ),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: _metricCard(
                "Rupture de stock",
                outOfStockCount.toString(),
                Icons.warning_amber_rounded,
                warningColor,
                onTap: () => _showOutOfStockModal(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _metricCard(
  String title,
  String value,
  IconData icon,
  Color color, {
  bool isBlueGradient = false,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: isBlueGradient
            ? const LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF0D47A1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isBlueGradient ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBlueGradient
              ? Colors.transparent
              : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 👉 ICONE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isBlueGradient
                  ? Colors.white.withOpacity(0.18)
                  : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isBlueGradient ? Colors.white : color,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // 👉 TEXTE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isBlueGradient ? Colors.white70 : Colors.black87,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: value.length > 10 ? 14 : 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isBlueGradient ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _cardWrapper(String title, double height, Widget child,
      {String? subtitle}) {
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
        [todaySales, monthlySales, yearlySales].reduce((a, b) => a > b ? a : b);
    final axisMax = maxYValue > 0 ? maxYValue * 1.4 : 100.0;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: axisMax,

        // 👉 INTERACTION
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

        // 👉 GROUPES
        barGroups: [
          _makeGroup(0, todaySales, darkBlue, _selectedBarIndex == 0, axisMax),
          _makeGroup(
              1, monthlySales, primaryYellow, _selectedBarIndex == 1, axisMax),
          _makeGroup(
              2, yearlySales, primaryOrange, _selectedBarIndex == 2, axisMax),
        ],

        // 👉 TITRES
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),

          // 🔥 MONTANTS EN HAUT
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();

                double val = 0;
                if (idx == 0) val = todaySales;
                if (idx == 1) val = monthlySales;
                if (idx == 2) val = yearlySales;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    NumberFormat.compact().format(val),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: idx == 2 ? primaryOrange : darkBlue,
                    ),
                  ),
                );
              },
            ),
          ),

          // 👉 BAS (TES BOUTONS)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                const titles = ['Ce Jour', 'Ce Mois', 'Cette Année'];
                const icons = [
                  Icons.today,
                  Icons.calendar_view_month,
                  Icons.bar_chart
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
                              color: isSelected ? darkBlue : Colors.grey[300]!,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: darkBlue.withOpacity(0.2),
                                      blurRadius: 5,
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icons[idx],
                                size: 12,
                                color: isSelected ? primaryYellow : Colors.grey,
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
          width: isTouched ? 22 : 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: axisMax,
            color:
                isTouched ? color.withOpacity(0.05) : const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  void _executeBarAction(int index) {
    final today = DateTime.now();
    String? start;
    String? end;
    String periodTitle = "";

    if (index == 0) {
      periodTitle = "Ce Jour";
      start = DateTime(today.year, today.month, today.day).toIso8601String();
      end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    } else if (index == 1) {
      periodTitle = "Ce Mois";
      start = DateTime(today.year, today.month, 1).toIso8601String();
      end = DateTime(today.year, today.month + 1, 0, 23, 59, 59).toIso8601String();
    } else if (index == 2) {
      periodTitle = "Cette Année";
      start = DateTime(today.year, 1, 1).toIso8601String();
      end = DateTime(today.year + 1, 1, 0, 23, 59, 59).toIso8601String();
    } else {
      return;
    }

    _showSoldProductsModal(context, periodTitle: periodTitle, startDate: start, endDate: end);
  }

  void _showSoldProductsModal(BuildContext context, {String? periodTitle, String? startDate, String? endDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: successColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2, color: successColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            periodTitle != null
                               ? "Articles vendus ($periodTitle)"
                               : "Articles vendus",
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: darkBlue,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _exitDao.getSoldProductsWithQty(startDate: startDate, endDate: endDate),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Erreur: ${snapshot.error}"));
                        }
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  "Aucune vente enregistrée",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final name = item['name'] as String? ?? 'Inconnu';
                            final category = item['category'] as String? ?? 'Sans catégorie';
                            final qty = item['total_qty'] as num? ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.shopping_basket_outlined, color: darkBlue, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "$qty vendus",
                                      style: const TextStyle(
                                        color: successColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showOutOfStockModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: warningColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Produits en rupture de stock",
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: darkBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<ProductModel>>(
                      future: _productDao.getOutOfStockProducts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Erreur: ${snapshot.error}"));
                        }
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 64, color: successColor),
                                const SizedBox(height: 16),
                                Text(
                                  "Aucun produit en rupture !",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final name = item.title;
                            final category = item.category ?? 'Sans catégorie';
                            final qty = item.quantity ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accentRed.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.warning_amber_rounded, color: accentRed, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: accentRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Stock: $qty",
                                      style: TextStyle(
                                        color: accentRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
