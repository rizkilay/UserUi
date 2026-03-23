import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

class CotisationScreen extends StatelessWidget {
  const CotisationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "15 000 Fcfa / mois",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Début : 11 jan",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
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
            const Text(
              "Statistiques",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF444444),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 230,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Montant disponible",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "1 050 Fcfa",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C3E50),
                      ),
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
                    "750 550",
                    const Color(0xFFFF6B00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStatCard(
                    "En provenance de mes financeurs",
                    "300 050",
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
                  "Mes transactions",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Icon(Icons.receipt_long, color: Colors.grey[400]),
              ],
            ),
          ],
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
