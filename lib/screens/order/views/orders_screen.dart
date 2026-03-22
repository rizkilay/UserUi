import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/components/product/secondary_product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/theme/input_decoration_theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // LE CONTENEUR PRINCIPAL AVEC OMBRE
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 20), // Espace sous les filtres
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildSearchBar(context),
                  _buildFilterTabs(),
                ],
              ),
            ),
            
            // Le reste du contenu (Liste des commandes)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(defaultPadding),
                itemCount: demoPopularProducts.length,
                itemBuilder: (context, index) => SecondaryProductCard(
                  image: demoPopularProducts[index].image,
                  brandName: demoPopularProducts[index].brandName,
                  title: demoPopularProducts[index].title,
                  price: demoPopularProducts[index].price,
                  priceAfetDiscount: demoPopularProducts[index].priceAfetDiscount,
                  dicountpercent: demoPopularProducts[index].dicountpercent,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 114),
                    maximumSize: const Size(double.infinity, 114),
                    padding: const EdgeInsets.all(8),
                  ),
                  press: () {
                    Navigator.pushNamed(context, productDetailsScreenRoute,
                        arguments: index.isEven);
                  },
                ),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: defaultPadding),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header identique avec le bouton dégradé ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 5),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          const SizedBox(width: 4),
           Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Commandes", style: Theme.of(context).textTheme.titleSmall,),
                Text("5 commandes", style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                SizedBox(width: 6),
                Text("28 000", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Barre de recherche grise claire ---
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Form(
        child: TextFormField(
          onChanged: (value) {},
          onSaved: (value) {},
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: "Rechercher une commande...",
            filled: false,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: secodaryOutlineInputBorder(context),
            enabledBorder: secodaryOutlineInputBorder(context),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SvgPicture.asset(
                "assets/icons/Search.svg",
                height: 20,
                color: Theme.of(context).iconTheme.color!.withOpacity(0.3),
              ),
            ),
            suffixIcon: SizedBox(
              width: 40,
              child: Row(
                children: [
                  const SizedBox(
                    height: 22,
                    child: VerticalDivider(width: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Filtres en bas du conteneur ---
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterCard("Toutes (5)", isSelected: true),
          const SizedBox(width: 8),
          _filterCard("Fournisseurs (3)"),
          const SizedBox(width: 8),
          _filterCard("Central (2)"),
        ],
      ),
    );
  }

  Widget _filterCard(String label, {bool isSelected = false, IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E63EE) : const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
