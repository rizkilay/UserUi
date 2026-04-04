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
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: _showAddExpenseForm,
          backgroundColor: const Color(0xFF3377B0),
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
          label: const Text(
            "Ajouter",
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<List<Expense>>(
                future: _expenseDao.getAll(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Erreur : ${snapshot.error}");
                  }

                  final expenses = snapshot.data ?? [];

                  double totalAmount = 0;
                  double monthlyTotal = 0;
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

                    if (e.dateTime.year == now.year &&
                        e.dateTime.month == now.month) {
                      monthlyTotal += e.amount;

                      if (earliestDateOfMonth == null ||
                          e.dateTime.isBefore(earliestDateOfMonth)) {
                        earliestDateOfMonth = e.dateTime;
                      }
                    }
                  }

                  String debutText = earliestDateOfMonth != null
                      ? "Début : ${DateFormat('dd MMM', 'fr_FR').format(earliestDateOfMonth)}"
                      : "Début : ${DateFormat('MMMM', 'fr_FR').format(now)}";

                  final NumberFormat formatter =
                      NumberFormat.decimalPattern('fr_FR');

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
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50)),
                          ),
                          const Text("Total des dépenses",
                              style: TextStyle(fontSize: 11, color: Color(0xFF3664FA))), 
                        ],
                      ),
                    ],
                  ),

                      const SizedBox(height: 24),

                      Text(
                        "Dépenses (Ce mois)",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 12),

                     Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20), // Padding augmenté pour laisser respirer
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey[200]!), // Plus arrondi = plus moderne
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF2C3E50).withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: Row(
    children: [
      // Section Texte
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              debutText.toUpperCase(), // Passage en majuscules pour un look "label"
              style: TextStyle(
                color: Colors.blueGrey[300],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${formatter.format(monthlyTotal)} FCFA",
              style: const TextStyle(
                fontSize: 22, // Légèrement plus grand
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A), // Noir plus profond
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      
      // Section Icône stylisée
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8), // Fond d'icône léger
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(
          'assets/images/expenses.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
      ),
    ],
  ),
),

                      const SizedBox(height: 16),

Row(
  children: [
    Expanded(
      child: _buildMiniStatCard(
        "Caisse",
        formatter.format(caisseAmount),
        const Color(0xFFFF6B00), // Orange
        Icons.account_balance_wallet_outlined, // Icône de portefeuille fine
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildMiniStatCard(
        "Finance",
        formatter.format(financeurAmount),
        const Color(0xFFEBC12F), // Jaune (légèrement ajusté pour la lisibilité)
        Icons.trending_up_rounded, // Icône de tendance/croissance
      ),
    ),
  ],
),

                      const SizedBox(height: 32),

                      Text(
                        "Détails des dépenses",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 12),

                      if (expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Aucune dépense enregistrée.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          separatorBuilder: (context, index) =>
                              const Divider(),
                          itemBuilder: (context, index) {
                            final expense = expenses[index];

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3377B0)
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.outbound,
                                    color: Color(0xFF3377B0)),
                              ),
                              title: Text(
                                expense.reason,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy', 'fr_FR')
                                            .format(expense.dateTime),
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    expense.description ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${formatter.format(expense.amount)} Fcfa",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getCategoryName(expense.category),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildMiniStatCard(String label, String amount, Color accentColor, IconData icon) {
  // Définir des couleurs dérivées pour l'esthétique
  final backgroundColor = accentColor.withOpacity(0.08); // Fond très clair
  final textColor = accentColor.withOpacity(0.8);      // Texte coloré mais doux

  return Container(
    padding: const EdgeInsets.all(16), // Padding généreux
    decoration: BoxDecoration(
      color: backgroundColor, // Fond coloré clair
      borderRadius: BorderRadius.circular(12), // Bordures bien arrondies
      border: Border.all(color: accentColor.withOpacity(0.2)), // Légère bordure
    ),
    child: Row(
      children: [
        // Icône à gauche, fine et colorée
        Icon(
          icon,
          color: accentColor,
          size: 24, // Taille d'icône standard
        ),
        const SizedBox(width: 12), // Espace après l'icône
        
        // Texte (Label et Montant)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // S'adapte au contenu
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor, // Texte coloré doux
                ),
              ),
              const SizedBox(height: 2), // Petit espace
              Text(
                "$amount FCFA", // Montant
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Noir doux pour le montant
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.entretien:
        return "Entretien";
      case ExpenseCategory.achatMateriel:
        return "Achat Matériel";
      case ExpenseCategory.investisseur:
        return "Investisseur";
      case ExpenseCategory.achatStock:
        return "Achat Stock";
    }
  }
}