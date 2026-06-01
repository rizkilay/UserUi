import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/database/exit_dao.dart';
import 'package:shop/models/stock_exit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shop/theme/input_decoration_theme.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final ExitDao _exitDao = ExitDao();
  List<StockExit> _invoices = [];
  List<StockExit> _filteredInvoices = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterInvoices(_searchController.text);
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _exitDao.getAllUniqueByUuid();
      if (mounted) {
        setState(() {
          _invoices = invoices;
          _filteredInvoices = invoices;
          _isLoading = false;
        });
        _filterInvoices(_searchController.text);
      }
    } catch (e) {
      debugPrint("Error loading invoices: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterInvoices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredInvoices = List.from(_invoices);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredInvoices = _invoices.where((invoice) {
          final uuid = invoice.uuid.toLowerCase();
          final name = invoice.name.toLowerCase();
          return uuid.contains(lowerQuery) || name.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildSearchBar(context),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadInvoices,
                      child: _filteredInvoices.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(child: Text("Aucun reçu trouvé.")),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(defaultPadding),
                              itemCount: _filteredInvoices.length,
                              separatorBuilder: (context, index) => const SizedBox(height: defaultPadding),
                              itemBuilder: (context, index) {
                                final invoice = _filteredInvoices[index];
                                return _buildInvoiceCard(context, invoice);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          Text(
            "Mes Reçus",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            "${_invoices.length} total",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Form(
        child: TextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: "Recherche",
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

  Widget _buildInvoiceCard(BuildContext context, StockExit invoice) {
    final date = invoice.createdAt != null ? DateTime.parse(invoice.createdAt!) : DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
    final NumberFormat formatter = NumberFormat.decimalPattern('fr_FR');
    final shortUuid = invoice.uuid.length > 8 ? invoice.uuid.substring(0, 8) : invoice.uuid;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        try {
          final details = await _exitDao.getByUuid(invoice.uuid);
          if (mounted) {
            _showReceiptDetails(invoice.uuid, invoice.name, details);
          }
        } catch (e) {
          debugPrint("Error loading invoice details: $e");
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: blackColor10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "#$shortUuid",
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              invoice.name.isEmpty ? "Client de passage" : invoice.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15 , color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${invoice.quantity} produits",
                  style: TextStyle(color:Color(0xFF2C3E50), fontSize: 13),
                ),
                Text(
                  "${formatter.format(invoice.amount)} Fcfa",
                  style: const TextStyle(
                    color:Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetails(String uuid, String clientName, List<StockExit> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final NumberFormat formatter = NumberFormat.decimalPattern('fr_FR');
        final double total = items.fold(0.0, (sum, item) => sum + item.amount);
        final shortUuid = uuid.length > 8 ? uuid.substring(0, 8) : uuid;
        final dateStr = items.isNotEmpty ? (items.first.createdAt ?? '') : '';
        final date = dateStr.isNotEmpty ? DateTime.parse(dateStr) : DateTime.now();
        final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

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
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Reçu #$shortUuid",
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Client Information Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text(
                          "Client : ",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        Text(
                          clientName.isEmpty ? "Client de passage" : clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Items list
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final productName = item.productName ?? "Produit inconnu";
                        final category = item.category ?? "Sans catégorie";
                        final quantity = item.quantity;
                        final lineAmount = item.amount;
                        final unitPrice = quantity > 0 ? (lineAmount / quantity) : lineAmount;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shopping_basket_outlined, color: Colors.blue, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$quantity x ${formatter.format(unitPrice)} Fcfa",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${formatter.format(lineAmount)} Fcfa",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Bottom Summary Block
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "TOTAL",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            "${formatter.format(total)} Fcfa",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
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
