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


import 'package:shop/database/exit_dao.dart';
import 'package:shop/models/stock_exit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ExitDao _exitDao = ExitDao();
  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = true;
  List<ProductModel> soldProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedClient = "Client";
  double reduction = 0.0;

  double _calculateTotal() {
    return soldProducts.fold(0.0, (sum, item) => sum + (item.priceAfetDiscount ?? item.price));
  }

  @override
  void initState() {
    super.initState();
    _loadLocalAndSync();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterProducts(_searchController.text);
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        final lowerQuery = query.toLowerCase();
        filteredProducts = products.where((product) {
          final title = product.title.toLowerCase();
          final brand = product.brandName?.toLowerCase() ?? "";
          final category = product.category?.toLowerCase() ?? "";
          return title.contains(lowerQuery) || brand.contains(lowerQuery) || category.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadLocalAndSync() async {
    // 1. Charger immédiatement depuis la DB locale
    try {
      final localProducts = await SyncService.instance.getLocalProducts();
      if (mounted) {
        setState(() {
          products = localProducts;
          filteredProducts = List.from(localProducts);
          isLoading = localProducts.isEmpty; // loading state only if db empty
        });
        _filterProducts(_searchController.text);
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
          filteredProducts = List.from(syncedProducts);
          isLoading = false;
        });
        _filterProducts(_searchController.text);
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

  Future<void> recordAllSales() async {
    if (soldProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit sélectionné.')),
      );
      return;
    }

    setState(() => isLoading = true);

    int successCount = 0;
    try {
      final uuid = const Uuid().v4();
      for (var product in soldProducts) {
        // Save locally
        await _exitDao.insert(StockExit(
          uuid: uuid,
          name: selectedClient, // Default client name
          productId: product.id,
          productName: product.title,
          quantity: 1,
          amount: product.priceAfetDiscount ?? product.price,
          createdAt: DateTime.now().toIso8601String(),
        ));

        // Save remotely
        try {
          await http.post(
            Uri.parse('https://backend-boutique.vercel.app/api/sales'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_id': product.id,
              'transaction_id': uuid,
              'quantity': 1,
              'amount': product.priceAfetDiscount ?? product.price,
            }),
          );
          successCount++;
        } catch (e) {
          debugPrint('Remote error for sale: $e');
          // We still increment success count if local save succeeded? 
          // Usually, yes, since it's now in the local DB.
          successCount++;
        }
      }

      if (mounted) {
        setState(() {
          soldProducts.clear();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount vente(s) enregistrée(s) avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh after sales
        await fetchProducts();
      }
    } catch (e) {
      debugPrint('Error recording sales: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    }
  }

  void _onProductClicked(ProductModel product) {
    setState(() {
      soldProducts.add(product);
      // Diminuer la quantité localement dans les deux listes
      final idx = products.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        final updatedProduct = ProductModel(
          id: products[idx].id,
          image: products[idx].image,
          brandName: products[idx].brandName,
          title: products[idx].title,
          price: products[idx].price,
          priceAfetDiscount: products[idx].priceAfetDiscount,
          dicountpercent: products[idx].dicountpercent,
          quantity: (products[idx].quantity ?? 0) > 0 ? products[idx].quantity! - 1 : 0,
          category: products[idx].category,
          description: products[idx].description,
        );
        products[idx] = updatedProduct;
        
        final fIdx = filteredProducts.indexWhere((p) => p.id == product.id);
        if (fIdx != -1) {
          filteredProducts[fIdx] = updatedProduct;
        }
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      for (var soldItem in soldProducts) {
        final idx = products.indexWhere((p) => p.id == soldItem.id);
        if (idx != -1) {
          final restoredProduct = ProductModel(
            id: products[idx].id,
            image: products[idx].image,
            brandName: products[idx].brandName,
            title: products[idx].title,
            price: products[idx].price,
            priceAfetDiscount: products[idx].priceAfetDiscount,
            dicountpercent: products[idx].dicountpercent,
            quantity: (products[idx].quantity ?? 0) + 1,
            category: products[idx].category,
            description: products[idx].description,
          );
          products[idx] = restoredProduct;

          final fIdx = filteredProducts.indexWhere((p) => p.id == soldItem.id);
          if (fIdx != -1) {
            filteredProducts[fIdx] = restoredProduct;
          }
        }
      }
      soldProducts.clear();
    });
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
                  _buildActionButtons(),
                ],
              ),
            ),
            
            // Le reste du contenu (Liste des commandes/produits)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: fetchProducts,
                      child: filteredProducts.isEmpty 
                          ? const Center(child: Text("Aucun produit trouvé."))
                          : ListView.separated(
                              padding: const EdgeInsets.all(defaultPadding),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return SecondaryProductCard(
                                    image: product.image,
                                    brandName: product.brandName,
                                    title: product.title,
                                    price: product.price,
                                    priceAfetDiscount: product.priceAfetDiscount,
                                    dicountpercent: product.dicountpercent,
                                    quantity: product.quantity,
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 114),
                                      maximumSize: const Size(double.infinity, 114),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    press: () => _onProductClicked(product),
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

  // Confirmation Removed

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
                Text("${soldProducts.length} produits", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                Text(
                  soldProducts.isNotEmpty ? "${_calculateTotal().toStringAsFixed(0)} F" : "0 F",
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
          controller: _searchController,
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

Widget _buildActionButtons() {
  bool hasItems = soldProducts.isNotEmpty;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    child: Row(
      children: [
        _infoTag("${soldProducts.length} Article(s)", Icons.shopping_bag_outlined),
        const Spacer(),
        
        // Animation de l'apparition du bouton d'annulation
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: hasItems ? 1.0 : 0.0,
          child: hasItems 
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _cancelSelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ),
              )
            : const SizedBox.shrink(),
        ),

        // Bouton Encaisser avec AnimatedContainer
        GestureDetector(
          onTap: hasItems ? () => _showOrderSummaryModal(context) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              // La couleur change de gris à vert selon l'état
              color: hasItems ? const Color(0xFF10B981) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // L'ombre s'anime aussi (devient transparente si inactif)
                  color: hasItems 
                      ? const Color(0xFF10B981).withOpacity(0.3) 
                      : Colors.transparent,
                  blurRadius: hasItems ? 8 : 0,
                  offset: hasItems ? const Offset(0, 3) : Offset.zero,
                ),
              ],
            ),
            child: const Text(
              "Encaisser",
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _infoTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
  void _showOrderSummaryModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// =========================
            /// ORDER SUMMARY CARD
            /// =========================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Résumé de la commande",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Subtotal
                  _summaryRow(
                    "Subtotal",
                    "${_calculateTotal().toStringAsFixed(0)} F",
                  ),

                  const SizedBox(height: 12),

                  /// Shipping
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reduction",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
GestureDetector(
  onTap: () => _showReductionDialog(context),
  child: Row(
    mainAxisSize: MainAxisSize.min, // Important : pour que le Row ne prenne pas toute la largeur
    children: [
      Icon(
        Icons.edit, // Une icône de réduction/étiquette
        color: Colors.green,
      ),
      SizedBox(width: 4), // Petit espace entre l'icône et le texte
      Text(
        "${reduction.toStringAsFixed(0)} F",
        style: TextStyle(
          fontSize: 15,
          color: Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),
                    ],
                  ),
                  
                 const SizedBox(height: 16),

                  Divider(color: Colors.grey.withOpacity(0.4)),

                  const SizedBox(height: 16),

                  /// Total
                  _summaryRow(
                    "À payer",
                    "${(_calculateTotal() - reduction).toStringAsFixed(0)} F",
                    isBold: true,
                  ),

                  const SizedBox(height: 10),

                  /// Client
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
  Text(
    "Client",
    style: TextStyle(
      fontSize: 13,
      color: Colors.grey,
      fontWeight: FontWeight.w400,
    ),
  ),

  InkWell(
    onTap: () => _showClientDialog(context),
    child: Row(
      children: [
        Icon(Icons.edit, size: 16, color: Colors.grey),

        SizedBox(width: 6),

        Text(
          selectedClient,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// =========================
            /// BOUTON CONTINUE (GRADIENT)
            /// =========================
            Container(
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7F5AF0),
                    Color(0xFF5F6BFF),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    recordAllSales();
                  },
                  child: const Center(
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
  Widget _filterCard(String label, {bool isBlue = false, bool isGreen = false, IconData? icon}) {
    Color bgColor = const Color(0xFFF4F6F8);
    Color textColor = Colors.black54;

    if (isGreen) {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else if (isBlue) {
      bgColor = const Color(0xFF1E63EE);
      textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isBold = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    ],
  );
}

void _showClientDialog(BuildContext context) {
    TextEditingController clientController = TextEditingController(text: selectedClient);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // <--- Ajoute cette ligne ici
          surfaceTintColor: Colors.transparent, // Optionnel : évite les teintes bleutées de Material 3
          title: Text("Sélectionner un client"),
          content: TextField(
            controller: clientController,
            decoration: InputDecoration(hintText: "Nom du client"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedClient = clientController.text.isEmpty ? "Client" : clientController.text;
                });
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
}

void _showReductionDialog(BuildContext context) {
    TextEditingController reductionController = TextEditingController(text: reduction.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Fond blanc
          surfaceTintColor: Colors.transparent, // Désactive la teinte Material 3
          title: Text("Modifier la réduction"),
          content: TextField(
            controller: reductionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Montant de réduction"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  reduction = double.tryParse(reductionController.text) ?? 0.0;
                });
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
}
}
