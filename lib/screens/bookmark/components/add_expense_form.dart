// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../components/custom_input_field.dart';
import '../../../../database/expense_dao.dart';
import '../../../../models/expense.dart';

class AddExpenseForm extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddExpenseForm({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _financeurNameController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.achatStock;
  ExpenseSource _selectedSource = ExpenseSource.caisse;
  DateTime _selectedDate = DateTime.now();

  final Color primaryColor = const Color(0xff193948);

  final ExpenseDao _expenseDao = ExpenseDao();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _financeurNameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSource == ExpenseSource.financement && _financeurNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Veuillez saisir le nom du financeur"),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: const Text("Veuillez saisir un montant valide"), backgroundColor: Colors.red[700]),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String reason;
        String? financeurId;

        if (_selectedSource == ExpenseSource.caisse) {
          reason = "Caisse";
        } else {
          reason = _financeurNameController.text.trim();
          financeurId = reason; // We save the name here since we don't have ids
        }

        final expense = Expense(
          reason: reason,
          amount: amount,
          category: _selectedCategory,
          dateTime: _selectedDate,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          source: _selectedSource,
          financeurId: financeurId,
        );

        await _expenseDao.insert(expense);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Dépense enregistrée avec succès"),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          widget.onSuccess();
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur: ${e.toString()}"), backgroundColor: Colors.red),
           );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getCategoryLabel(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.entretien: return 'Entretien';
      case ExpenseCategory.achatMateriel: return 'Matériel';
      case ExpenseCategory.investisseur: return 'Investisseur';
      case ExpenseCategory.achatStock: return 'Stock/Achat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "Nouvelle Dépense",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _buildSectionLabel("Source"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExpenseSource>(
                    value: _selectedSource,
                    isExpanded: true,
                    hint: const Text("Sélectionner une source"),
                    items: ExpenseSource.values.map((source) {
                      return DropdownMenuItem<ExpenseSource>(
                        value: source,
                        child: Text(source == ExpenseSource.caisse ? 'Caisse' : 'Financement'),
                      );
                    }).toList(),
                    onChanged: (source) {
                      setState(() {
                        _selectedSource = source ?? ExpenseSource.caisse;
                        if (_selectedSource == ExpenseSource.financement) {
                          _selectedCategory = ExpenseCategory.investisseur;
                        } else {
                          _selectedCategory = ExpenseCategory.achatStock;
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              if (_selectedSource == ExpenseSource.financement) ...[
                _buildSectionLabel("Nom du financeur"),
                CustomInputField(
                  controller: _financeurNameController,
                  icon: Icons.person_outline,
                  hint: "Nom du financeur",
                ),
                const SizedBox(height: 15),
              ],

              _buildSectionLabel("Montant"),
              CustomInputField(
                controller: _amountController,
                icon: Icons.account_balance_wallet_outlined,
                hint: "Montant (FCFA)",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildDatePicker(),
              const SizedBox(height: 15),

              _buildSectionLabel("Catégorie"),
              if (_selectedSource == ExpenseSource.financement)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Financement',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: ExpenseCategory.values.where((cat) => cat != ExpenseCategory.investisseur).map((category) {
                    final isSelected = _selectedCategory == category;
                    return ChoiceChip(
                      label: Text(_getCategoryLabel(category)),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _selectedCategory = category),
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 15),

              _buildSectionLabel("Description (optionnelle)"),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Détails supplémentaires...",
                  filled: true,
                  fillColor: Colors.grey[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF3377B0), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ENREGISTRER",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("Date de l'opération"),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2022),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
