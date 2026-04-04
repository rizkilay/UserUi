import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import '../components/add_cotisation_form.dart';
import '../../../database/cotisation_dao.dart';
import '../../../models/cotisation.dart';
import '../../../models/cotisation_withdrawal.dart';

class CotisationScreen extends StatefulWidget {
  const CotisationScreen({super.key});

  @override
  State<CotisationScreen> createState() => _CotisationScreenState();
}

class _CotisationScreenState extends State<CotisationScreen> {
  final CotisationDao _cotisationDao = CotisationDao();

  void _showAddCotisationForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddCotisationForm(
          onSuccess: () {
            Navigator.pop(context);
            setState(() {});
          },
        );
      },
    );
  }

void _showWithdrawForm() {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController motifController = TextEditingController();
  String selectedSource = 'caisse';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white, // <--- Couleur de fond blanche forcée
        surfaceTintColor: Colors.white, // Évite la coloration violette de Material 3
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet_outlined, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Retrait de fonds", style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Saisissez les informations relatives au retrait.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // Champ Montant
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Montant",
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.attach_money, color: Colors.black54),
                  suffixText: "FCFA",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  filled: true,
                  fillColor: Colors.white, // Fond du champ en blanc aussi
                ),
              ),
              const SizedBox(height: 16),

              // Champ Motif
              TextField(
                controller: motifController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: "Motif du retrait",
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.description_outlined, color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Sélecteur de Source
              DropdownButtonFormField<String>(
                value: selectedSource,
                dropdownColor: Colors.white, // Fond du menu déroulant
                style: const TextStyle(color: Colors.black87),
                onChanged: (val) {
                  setDialogState(() => selectedSource = val!);
                },
                decoration: InputDecoration(
                  labelText: "Source du prélèvement",
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.account_tree_outlined, color: Colors.black54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'caisse', child: Text('Caisse')),
                  DropdownMenuItem(value: 'partner', child: Text('Financeur')),
                ],
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.black45)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) {
                _showStatus(context, "Montant invalide", isError: true);
                return;
              }

              final res = await _cotisationDao.withdrawAmount(
                amount,
                selectedSource,
                motifController.text,
              );

              if (res > 0) {
                Navigator.pop(context);
                setState(() {});
                _showStatus(context, "Retrait effectué !");
              } else {
                _showStatus(context, res == -1.0 ? "Fonds insuffisants" : "Erreur", isError: true);
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text("Confirmer"),
          ),
        ],
      ),
    ),
  );
}
// Petite fonction utilitaire pour les messages
void _showStatus(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: _showAddCotisationForm,
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
              FutureBuilder<List<dynamic>>(
                future: _cotisationDao.getAllTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Erreur : ${snapshot.error}");
                  }

                  final transactions = snapshot.data ?? [];
                  final cotisations = transactions.whereType<Cotisation>().toList();

                  double totalAmount = 0;
                  double monthlyTotal = 0;
                  double caisseAmount = 0;
                  double financeurAmount = 0;

                  final now = DateTime.now();
                  DateTime? earliestDateOfMonth;

                  for (var c in cotisations) {
                    final amount = c.remaining ?? c.amount;
                    totalAmount += amount;

                    if (c.source.toLowerCase() == 'caisse') {
                      caisseAmount += amount;
                    } else {
                      financeurAmount += amount;
                    }

                    final date = DateTime.parse(c.date);

                    if (date.year == now.year && date.month == now.month) {
                      monthlyTotal += c.amount;

                      if (earliestDateOfMonth == null ||
                          date.isBefore(earliestDateOfMonth)) {
                        earliestDateOfMonth = date;
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
                          const Text("Solde total disponible",
                              style: TextStyle(fontSize: 12, color: Color(0xFF3664FA))),
                        ],
                      ),
IconButton.filled(
  onPressed: _showWithdrawForm,
  icon: const Icon(Icons.remove_circle_outline),
  style: IconButton.styleFrom(
    backgroundColor: const Color(0xFFF2A945),
    foregroundColor: Colors.white,
  ),
),
                    ],
                  ),

                      const SizedBox(height: 24),

                      Text(
                        "Cotisation (ce mois)",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 12),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20), // Padding augmenté pour laisser respirer
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16), 
    border: Border.all(color: Colors.grey[200]!),// Plus arrondi = plus moderne
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
          'assets/images/assets.png',
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
                        "Détails des cotisations",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),

                      const SizedBox(height: 12),

                      if (cotisations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Aucune cotisation enregistrée.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(),
                          itemBuilder: (context, index) {
                            final isWithdrawal = transactions[index] is CotisationWithdrawal;
                            final transaction = transactions[index];
                            final String dateString = isWithdrawal 
                                ? (transaction as CotisationWithdrawal).date 
                                : (transaction as Cotisation).date;
                            final String note = isWithdrawal 
                                ? (transaction as CotisationWithdrawal).motif ?? '' 
                                : (transaction as Cotisation).note ?? '';
                            final double amount = isWithdrawal 
                                ? (transaction as CotisationWithdrawal).amount 
                                : (transaction as Cotisation).amount;
                            final String source = isWithdrawal 
                                ? (transaction as CotisationWithdrawal).source ?? '' 
                                : (transaction as Cotisation).source;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isWithdrawal ? Colors.red : const Color(0xFFF2A945))
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isWithdrawal ? Icons.upload : Icons.download,
                                  color: isWithdrawal ? Colors.red : const Color(0xFFF2A945),
                                ),
                              ),
                              title: Text(
                                isWithdrawal 
                                    ? (source == 'caisse' ? 'Retrait Caisse' : 'Retrait Financeur')
                                    : _getCotisationTitle(transaction as Cotisation),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy', 'fr_FR')
                                            .format(DateTime.parse(dateString)),
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    note,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${formatter.format(amount)} Fcfa",
                                    style: TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    isWithdrawal ? "Retrait" : "Dépôt",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isWithdrawal ? Colors.red[300] : Colors.green[300],
                                      fontWeight: FontWeight.bold,
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

  String _getCotisationTitle(Cotisation cotisation) {
    if (cotisation.source == 'partner' && cotisation.note != null) {
      // Extract partner name from note like "Financier: John Doe - some note"
      final note = cotisation.note!;
      if (note.startsWith('Financier: ')) {
        final parts = note.split(' - ');
        if (parts.isNotEmpty) {
          final financierPart = parts[0].replaceFirst('Financier: ', '');
          return financierPart;
        }
      }
    }
    return cotisation.source == 'caisse' ? 'Caisse' : 'Financier';
  }

  bool _isPartnerNote(String note) {
    return note.startsWith('Financier: ');
  }
}