import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import '../components/add_cotisation_form.dart';
import '../../../database/cotisation_dao.dart';
import '../../../models/cotisation.dart';

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
            // Refresh data here if needed
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
    onPressed: _showAddCotisationForm,
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
            children: [              FutureBuilder<List<Cotisation>>(
                future: _cotisationDao.getAll(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Erreur : ${snapshot.error}");
                  }
                  
                  final cotisations = snapshot.data ?? [];
                  
                  double totalAmount = 0; // Global total
                  double monthlyTotal = 0; // Total for current month
                  double caisseAmount = 0;
                  double financeurAmount = 0;
                  
                  final now = DateTime.now();
                  DateTime? earliestDateOfMonth;

                  for (var c in cotisations) {
                    totalAmount += c.amount;
                    if (c.source == 'Caisse') {
                      caisseAmount += c.amount;
                    } else {
                      financeurAmount += c.amount;
                    }
                    
                    final date = DateTime.parse(c.date);
                    if (date.year == now.year && date.month == now.month) {
                      monthlyTotal += c.amount;
                      if (earliestDateOfMonth == null || date.isBefore(earliestDateOfMonth)) {
                        earliestDateOfMonth = date;
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
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2A945),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Retirer",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
            
                      // --- Section Statistiques ---
                      Text(
                        "Cotisation",
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
                                'assets/images/assets.png',
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
                            "Détails des cotisations",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (cotisations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Aucune cotisation enregistrée.", style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cotisations.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final cotisation = cotisations[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2A945).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.download, color: Color(0xFFF2A945)),
                              ),
                              title: Text(
                                cotisation.source,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(cotisation.date)) + 
                                (cotisation.note != null ? ' - ${cotisation.note}' : ''),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                "+ ${formatter.format(cotisation.amount)} Fcfa",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),  ),
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
