// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../components/custom_input_field.dart';
import '../../../../database/cotisation_dao.dart';
import '../../../../models/cotisation.dart';

class AddCotisationForm extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddCotisationForm({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<AddCotisationForm> createState() => _AddCotisationFormState();
}

class _AddCotisationFormState extends State<AddCotisationForm> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _categoryController = TextEditingController();
  final _partnerNameController = TextEditingController();

  String _source = 'caisse';
  DateTime _selectedDate = DateTime.now();

  final Color primaryColor = const Color(0xff193948);
  final Color accentColor = const Color(0xff4facfe);

  final CotisationDao _cotisationDao = CotisationDao();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_source == 'partner' && _partnerNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Veuillez saisir le nom du financier"),
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
        final category = _categoryController.text.trim();
        final note = _noteController.text.trim();

        // In ui-user, we don't have partnerId if they type manually. We just store the partner name in the note or category if we don't have a string field. 
        // Or we use note as standard. We can prepend the partner name to the note.
        String finalNote = note;
        if (_source == 'partner') {
           final partnerName = _partnerNameController.text.trim();
           finalNote = 'Financier: $partnerName' + (note.isNotEmpty ? ' - $note' : '');
        }

        final cotisation = Cotisation(
          amount: amount,
          date: _selectedDate.toIso8601String(),
          note: finalNote.isNotEmpty ? finalNote : null,
          source: _source,
          category: category.isNotEmpty ? category : null,
          partnerId: null, // Because we type manually now
        );

        await _cotisationDao.insert(cotisation);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Cotisation enregistrée avec succès"),
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
                    "Nouvelle Cotisation",
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

              _buildSectionLabel("Montant"),
              CustomInputField(
                controller: _amountController,
                icon: Icons.monetization_on_rounded,
                hint: "Montant",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              _buildSectionLabel("Source"),
              _buildSourceSelector(),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _source == 'partner'
                    ? Column(
                        key: const ValueKey('partner_field'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 15),
                          _buildSectionLabel("Nom du financier"),
                          CustomInputField(
                            controller: _partnerNameController,
                            icon: Icons.person_outline,
                            hint: "Nom du financier",
                          ),
                        ],
                      )
                    : const SizedBox(key: ValueKey('empty_field')),
              ),

              const SizedBox(height: 15),
              _buildDatePicker(),

              const SizedBox(height: 15),
              _buildSectionLabel("Motif ou Note"),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Détails",
                  filled: true,
                  fillColor: Colors.grey[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
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
                    backgroundColor: const Color(0xFF3377B0),
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
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildSourceSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['caisse', 'partner'].map((type) {
          bool isSelected = _source == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _source = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Center(
                  child: Text(
                    type == 'caisse' ? "Caisse" : "Financier",
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel("Date de réception"),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
