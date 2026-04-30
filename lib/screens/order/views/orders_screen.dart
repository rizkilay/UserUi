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
//import 'package:uuid/uuid.dart';
import 'dart:math';


import 'package:shop/database/exit_dao.dart';
import 'package:shop/models/stock_exit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

String generateShortUuid() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final random = Random();

  final letterPart =
      letters[random.nextInt(letters.length)] +
      letters[random.nextInt(letters.length)];

  final numberPart = random.nextInt(1000).toString().padLeft(4, '0');

  return '$letterPart$numberPart'; 
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ExitDao _exitDao = ExitDao();
  List<ProductModel> products = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = true;
  List<Map<String, dynamic>> selectedItems = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String selectedClient = "Client";
  double reduction = 0.0;
  bool isRecordingSale = false;

  double _calculateTotal() {
    return selectedItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  void initState() {
    super.initState();
    _loadLocalAndSync();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        final lowerQuery = query.trim().toLowerCase();
        filteredProducts = products.where((product) {
          final title = product.title.toLowerCase();
          final brand = product.brandName?.toLowerCase() ?? "";
          final category = product.category?.toLowerCase() ?? "";
          final tags = product.tags.join(" ").toLowerCase();
          return title.contains(lowerQuery) || brand.contains(lowerQuery) || category.contains(lowerQuery) || tags.contains(lowerQuery);
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
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit sélectionné.')),
      );
      return;
    }

    setState(() => isRecordingSale = true);

    int successCount = 0;
    try {
      final String uuid = generateShortUuid();
      // Distribute reduction proportionally
      double totalBeforeReduction = _calculateTotal();

      for (var item in selectedItems) {
        final ProductModel product = item['product'];
        final int qty = item['quantity'];
        double amount = item['price'] * qty;

        if (totalBeforeReduction > 0 && reduction > 0) {
          double itemReduction = reduction * (amount / totalBeforeReduction);
          amount -= itemReduction;
        }

        // Save locally only
        await _exitDao.insert(StockExit(
          uuid: uuid,
          name: selectedClient,
          productId: product.id,
          productName: product.title,
          quantity: qty,
          amount: amount,
          createdAt: DateTime.now().toIso8601String(),
        ));
        successCount++;
      }

      if (mounted) {
        setState(() {
          selectedItems.clear();
          reduction = 0.0;
          isRecordingSale = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount vente(s) enregistrée(s) avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh after sales
        // Removed automatic refresh to preserve local quantity updates after sale
      }
    } catch (e) {
      debugPrint('Error recording sales: $e');
      if (mounted) {
        setState(() => isRecordingSale = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
        );
      }
    }
  }

  void _onProductClicked(ProductModel product) {
    setState(() {
      final existingIndex = selectedItems.indexWhere((item) => item['product'].id == product.id);
      if (existingIndex != -1) {
        selectedItems[existingIndex]['quantity'] += 1;
      } else {
        selectedItems.add({
          'product': product,
          'quantity': 1,
          'price': product.priceAfetDiscount ?? product.price,
        });
      }

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
          tags: products[idx].tags,
        );
        products[idx] = updatedProduct;
        
        final fIdx = filteredProducts.indexWhere((p) => p.id == product.id);
        if (fIdx != -1) {
          filteredProducts[fIdx] = updatedProduct;
        }
      }
    });
    
    // Focus la barre de recherche et sélectionne le texte
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  void _cancelSelection() {
    setState(() {
      for (var item in selectedItems) {
        final ProductModel soldItem = item['product'];
        final int qty = item['quantity'];
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
            quantity: (products[idx].quantity ?? 0) + qty,
            category: products[idx].category,
            description: products[idx].description,
            tags: products[idx].tags,
          );
          products[idx] = restoredProduct;

          final fIdx = filteredProducts.indexWhere((p) => p.id == soldItem.id);
          if (fIdx != -1) {
            filteredProducts[fIdx] = restoredProduct;
          }
        }
      }
      selectedItems.clear();
      reduction = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                                    category: product.category,
                                    title: product.title,
                                    price: product.price,
                                    priceAfetDiscount: product.priceAfetDiscount,
                                    dicountpercent: product.dicountpercent,
                                    quantity: product.quantity,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
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
                Text("${selectedItems.length} produits", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                  selectedItems.isNotEmpty ? "${_calculateTotal().toStringAsFixed(0)} F" : "0 F",
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
          focusNode: _searchFocusNode,
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
  bool hasItems = selectedItems.isNotEmpty;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    child: Row(
      children: [
        GestureDetector(
          onTap: hasItems ? () => _showBasketManager(context) : null,
          child: _infoTag("${selectedItems.length} Article(s)", Icons.shopping_bag_outlined),
        ),
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
  void _showOrderSummaryModal(BuildContext context) async {
    _searchFocusNode.unfocus();
    await showModalBottomSheet(
      context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: 0,
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

                  ...selectedItems.map((item) {
                      final ProductModel p = item['product'];
                      final int qty = item['quantity'];
                      final double price = item['price'];
                      final double total = price * qty;
                      final title = qty > 1 ? "${p.title} (x$qty)" : "${p.title}";
                      return _summaryRow(title, "${total.toStringAsFixed(0)} F");
                    }).toList(),

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
                  onTap: isRecordingSale ? null : () async {
                    setState(() => isRecordingSale = true);
                    try {
                      await recordAllSales();
                    } finally {
                      if (mounted) {
                        setState(() => isRecordingSale = false);
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Center(
                    child: isRecordingSale
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
  if (mounted) {
    _searchFocusNode.requestFocus();
  }
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

  void _showBasketManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: 0,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Modifier les articles",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selectedItems.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = selectedItems[index];
                        final ProductModel p = item['product'];
                        return ListTile(
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(
                            children: [
                              // Quantity editing
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  if (item['quantity'] > 1) {
                                    setModalState(() => item['quantity']--);
                                    setState(() {}); // Update main screen
                                  }
                                },
                              ),
                              Text("${item['quantity']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () {
                                  setModalState(() => item['quantity']++);
                                  setState(() {}); // Update main screen
                                },
                              ),
                              const Spacer(),
                              // Price editing
                              GestureDetector(
                                onTap: () => _showItemPriceDialog(context, index, setModalState),
                                child: Text(
                                  "${item['price'].toStringAsFixed(0)} F",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () {
                              setModalState(() {
                                selectedItems.removeAt(index);
                              });
                              setState(() {}); // Update main screen
                              if (selectedItems.isEmpty) Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showItemPriceDialog(BuildContext context, int index, StateSetter setModalState) {
    TextEditingController controller = TextEditingController(text: selectedItems[index]['price'].toString());
    FocusNode focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
            controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
          }
        });
        return AlertDialog(
          title: const Text("Modifier le prix"),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: "Prix unitaire"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            TextButton(
              onPressed: () {
                setModalState(() {
                  selectedItems[index]['price'] = double.tryParse(controller.text) ?? selectedItems[index]['price'];
                });
                setState(() {}); // Update main screen
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Remove the old _buildSoldProductsList helper as it is replaced

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
    FocusNode reductionFocusNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (reductionFocusNode.canRequestFocus) {
            reductionFocusNode.requestFocus();
            reductionController.selection = TextSelection(baseOffset: 0, extentOffset: reductionController.text.length);
          }
        });
        return AlertDialog(
          backgroundColor: Colors.white, // Fond blanc
          surfaceTintColor: Colors.transparent, // Désactive la teinte Material 3
          title: Text("Modifier la réduction"),
          content: TextField(
            controller: reductionController,
            focusNode: reductionFocusNode,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
