import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shop/constants.dart';
import 'package:shop/database/exit_dao.dart';
import 'package:shop/models/stock_exit.dart';

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
            _buildHeader(context),
            _buildSearchBar(context),
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
      padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Recherche",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, StockExit invoice) {
    final date = invoice.createdAt != null ? DateTime.parse(invoice.createdAt!) : DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
    final NumberFormat formatter = NumberFormat.decimalPattern('fr_FR');
    final shortUuid = invoice.uuid.length > 8 ? invoice.uuid.substring(0, 8) : invoice.uuid;

    return Container(
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
    );
  }
}
