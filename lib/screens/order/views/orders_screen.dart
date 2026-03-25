import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shop/components/product/secondary_product_card.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/product_model.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/sync_service.dart';
import 'package:shop/theme/input_decoration_theme.dart';
import 'package:uuid/uuid.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<ProductModel> products = [];
  bool isLoading = true;
  Set<int> sentProductIds = {}; // Local track to avoid duplicate clicks in same session

  @override
  void initState() {
    super.initState();
    _loadLocalAndSync();
  }

  Future<void> _loadLocalAndSync() async {
    // 1. Charger immédiatement depuis la DB locale
    try {
      final localProducts = await SyncService.instance.getLocalProducts();
      if (mounted) {
        setState(() {
          products = localProducts;
          isLoading = localProducts.isEmpty; // loading state only if db empty
        });
      }
    } catch (e) {
      debugPrint("Error loading local: $e");
    }

    // 2. Sync en arrière-plan
    try {
      final syncedProducts = await SyncService.instance.fetchAndSyncProducts();
      if (mounted) {
        setState(() {
          products = syncedProducts;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error syncing products: $e");
      if (mounted && products.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les produits (mode hors ligne)')),
        );
      }
    }
  }

  Future<void> fetchProducts() async {
    // called on pull-to-refresh
    await _loadLocalAndSync();
  }

  Future<void> recordSale(ProductModel product) async {
    final transactionId = const Uuid().v4();
    try {
      final response = await http.post(
        Uri.parse('https://backend-boutique.vercel.app/api/sales'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': product.id,
          'transaction_id': transactionId,
          'quantity': 1,
          'amount': product.priceAfetDiscount ?? product.price,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          sentProductIds.add(product.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vente de ${product.title} enregistrée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to record sale');
      }
    } catch (e) {
      debugPrint('Error recording sale: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement de la vente: $e')),
        );
      }
    }
  }

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
            
            // Le reste du contenu (Liste des commandes/produits)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchProducts,
                      child: products.isEmpty 
                          ? const Center(child: Text("Aucun produit disponible pour la vente."))
                          : ListView.separated(
                              padding: const EdgeInsets.all(defaultPadding),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final isSent = sentProductIds.contains(product.id);
                                return SecondaryProductCard(
                                  image: product.image,
                                  brandName: product.brandName,
                                  title: product.title,
                                  price: product.price,
                                  priceAfetDiscount: product.priceAfetDiscount,
                                  dicountpercent: product.dicountpercent,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 114),
                                    maximumSize: const Size(double.infinity, 114),
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: isSent ? Colors.grey[100] : null,
                                  ),
                                  press: isSent ? null : () {
                                    _showSaleConfirmation(product);
                                  },
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: defaultPadding),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleConfirmation(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la vente"),
        content: Text("Voulez-vous enregistrer la vente de ${product.title} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              recordSale(product);
            },
            child: const Text("Confirmer"),
          ),
        ],
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
                Text("Ventes disponibles", style: Theme.of(context).textTheme.titleSmall,),
                Text("${products.length} produits", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 13),
                const SizedBox(width: 6),
                Text(
                  products.length > 0 ? "Prêt" : "Vide",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
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
            hintText: "Rechercher un produit...",
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
          ),
        ),
      ),
    );
  }

  // --- Filtres en bas du conteneur ---
  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterCard("Tous (${products.length})", isSelected: true),
          const SizedBox(width: 8),
          _filterCard("Boutique App"),
        ],
      ),
    );
  }

  Widget _filterCard(String label, {bool isSelected = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E63EE) : const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.circle, size: 8, color: Colors.orange),
            const SizedBox(width: 6),
          ],
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
    );
  }
}
