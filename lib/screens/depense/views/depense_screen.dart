import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import '../../bookmark/components/add_expense_form.dart';
import '../../../database/expense_dao.dart';
import '../../../models/expense.dart';

class DepenseScreen extends StatefulWidget {
  const DepenseScreen({super.key});

  @override
  State<DepenseScreen> createState() => _DepenseScreenState();
}

class _DepenseScreenState extends State<DepenseScreen> {
  final ExpenseDao _expenseDao = ExpenseDao();

  void _showAddExpenseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddExpenseForm(
          onSuccess: () {
            Navigator.pop(context);
            // Refresh logic here
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
floatingActionButton: SizedBox(
  height: 45, // Réduit la hauteur
  child: FloatingActionButton.extended(
    onPressed: _showAddExpenseForm,
    backgroundColor: const Color(0xFF3377B0),
    icon: const Icon(Icons.add, color: Colors.white, size: 20),
    label: const Text(
      "Ajouter", 
      style: TextStyle(color: Colors.white, fontSize: 13) // Texte plus petit
    ),
  ),
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              FutureBuilder<List<Expense>>(
                future: _expenseDao.getAll(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Erreur : ${snapshot.error}");
                  }
                  
                  final expenses = snapshot.data ?? [];
                  
                  double totalAmount = 0; // Global total
                  double monthlyTotal = 0; // Total for current month
                  double caisseAmount = 0;
                  double financeurAmount = 0;
                  
                  final now = DateTime.now();
                  DateTime? earliestDateOfMonth;

                  for (var e in expenses) {
                    totalAmount += e.amount;
                    if (e.source == ExpenseSource.caisse) {
                      caisseAmount += e.amount;
                    } else {
                      financeurAmount += e.amount;
                    }
                    
                    if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
                      monthlyTotal += e.amount;
                      if (earliestDateOfMonth == null || e.dateTime.isBefore(earliestDateOfMonth)) {
                        earliestDateOfMonth = e.dateTime;
                      }
                    }
                  }

                  String debutText = earliestDateOfMonth != null 
                    ? "Début : ${DateFormat('dd MMM', 'fr_FR').format(earliestDateOfMonth)}" 
                    : "Début : ${DateFormat('MMMM', 'fr_FR').format(now)}";
                  
                  final NumberFormat formatter = NumberFormat.decimalPattern('fr_FR');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${formatter.format(totalAmount)} Fcfa",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                              ),
                              const Text(
                                "Somme totale",
                                style: TextStyle(fontSize: 11, color: Color(0xFF2C3E50)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
            
                      // --- Section Statistiques ---
                      Text(
                        "Dépenses",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debutText,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${formatter.format(monthlyTotal)} Fcfa",
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Image.asset(
                                'assets/images/expenses.png',
                                width: 50,
                                height: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
            
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStatCard(
                              "En provenance de la caisse",
                              formatter.format(caisseAmount),
                              const Color(0xFFFF6B00),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniStatCard(
                              "En provenance des financeurs",
                              formatter.format(financeurAmount),
                              const Color(0xFFFFCC00),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
            
                      // --- Section Mes Transactions ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            "Détails des dépenses",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Aucune dépense enregistrée.", style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3377B0).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.outbound, color: Color(0xFF3377B0)),
                              ),
                              title: Text(
                                expense.reason,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy', 'fr_FR').format(expense.dateTime) + 
                                (expense.description != null ? ' - ${expense.description}' : ''),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                "${formatter.format(expense.amount)} Fcfa",
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),     ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String amount, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  "$amount Fcfa",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
