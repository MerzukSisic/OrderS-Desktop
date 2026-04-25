// lib/features/admin/procurement/widgets/create_procurement_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/errors/ui_error_mapper.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/inventory/store_product_model.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';
import 'package:rs2_desktop/providers/business_providers.dart';

class CreateProcurementDialog extends StatefulWidget {
  const CreateProcurementDialog({super.key});

  @override
  State<CreateProcurementDialog> createState() =>
      _CreateProcurementDialogState();
}

class _CreateProcurementDialogState extends State<CreateProcurementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedStoreId;
  String? _selectedSourceStoreId;
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoresProvider>().fetchStores();
      context.read<InventoryProvider>().fetchStoreProducts();
    });
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: SingleChildScrollView(child: _buildForm())),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.add_shopping_cart,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Procurement Order',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Order supplies from your suppliers',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<StoresProvider>(
            builder: (context, provider, child) {
              if (provider.stores.isEmpty) {
                return const CircularProgressIndicator();
              }

              final internalStores = provider.stores
                  .where((s) => !s.isExternal)
                  .toList();

              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStoreId,
                    decoration: InputDecoration(
                      labelText: 'Destination Store',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                    dropdownColor: AppColors.surfaceVariant,
                    items: internalStores.map((store) {
                      return DropdownMenuItem(
                        value: store.id,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStoreId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a store';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedSourceStoreId,
                    decoration: InputDecoration(
                      labelText:
                          'Source Store (optional — leave empty for external supplier)',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                    dropdownColor: AppColors.surfaceVariant,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— None (enter supplier name below) —'),
                      ),
                      ...provider.stores.where((s) => s.isExternal).map((
                        store,
                      ) {
                        return DropdownMenuItem<String?>(
                          value: store.id,
                          child: Text(store.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSourceStoreId = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _supplierController,
            decoration: InputDecoration(
              labelText: 'Supplier Name',
              hintText: 'Enter supplier name',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter supplier name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Enter any additional notes',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No items added yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(index, item);
            }),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              item['productName'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Qty: ${item['quantity']}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unit: KM ${item['unitCost'].toStringAsFixed(2)}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'KM ${(item['quantity'] * item['unitCost']).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete),
            color: AppColors.error,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final totalAmount = _items.fold<double>(
      0,
      (sum, item) => sum + (item['quantity'] * item['unitCost']),
    );

    return Column(
      children: [
        if (_items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'KM ${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isLoading || _items.isEmpty ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Create Order'),
            ),
          ],
        ),
      ],
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => AddProcurementItemDialog(
        destinationStoreId: _selectedSourceStoreId,
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one item'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context
          .read<ProcurementProvider>()
          .createProcurementOrder(
            storeId: _selectedStoreId!,
            sourceStoreId: _selectedSourceStoreId,
            supplier: _supplierController.text,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
            items: _items,
          );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Procurement order created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<ProcurementProvider>().error ??
                  'Failed to create order',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            UiErrorMapper.fromException(
              e,
              fallback: 'Unable to create order right now.',
            ).userMessage,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Add Item Dialog
class AddProcurementItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final String? destinationStoreId;
  final List<StoreProductModel>? availableProducts;

  const AddProcurementItemDialog({
    super.key,
    required this.onAdd,
    this.destinationStoreId,
    this.availableProducts,
  });

  @override
  State<AddProcurementItemDialog> createState() =>
      _AddProcurementItemDialogState();
}

class _AddProcurementItemDialogState extends State<AddProcurementItemDialog> {
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  String? _selectedProductId;
  String? _selectedProductName;
  int? _availableStock;
  String? _stockUnit;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(() => setState(() {}));
    _unitCostController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  bool get _stockInsufficient {
    if (_availableStock == null || _quantityController.text.isEmpty) {
      return false;
    }
    final qty = int.tryParse(_quantityController.text);
    if (qty == null) return false;
    return qty > _availableStock!;
  }

  double? get _parsedUnitCost {
    final normalized = _unitCostController.text.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  bool get _isUnitCostInvalid {
    if (_unitCostController.text.trim().isEmpty) return false;
    final parsed = _parsedUnitCost;
    return parsed == null || parsed <= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                final baseProducts =
                    widget.availableProducts ?? provider.storeProducts;
                final products = widget.destinationStoreId != null
                    ? baseProducts
                          .where((p) => p.storeId == widget.destinationStoreId)
                          .toList()
                    : baseProducts;

                if (widget.availableProducts == null && provider.isLoading) {
                  return const CircularProgressIndicator();
                }

                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.destinationStoreId != null
                          ? 'No products found in this source store.'
                          : 'No products available.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  key: const Key('add_item_product'),
                  value: _selectedProductId,
                  decoration: InputDecoration(
                    labelText: 'Product',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: AppColors.surfaceVariant,
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product.id,
                      child: Text(product.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final product = products.firstWhere((p) => p.id == value);
                    setState(() {
                      _selectedProductId = value;
                      _selectedProductName = product.name;
                      _availableStock = product.currentStock;
                      _stockUnit = product.unit;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('add_item_quantity'),
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: _availableStock != null
                    ? 'Available: $_availableStock $_stockUnit'
                    : null,
                helperStyle: TextStyle(color: AppColors.textSecondary),
                errorText: _stockInsufficient
                    ? 'Insufficient stock — only $_availableStock $_stockUnit available'
                    : null,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('add_item_unit_cost'),
              controller: _unitCostController,
              decoration: InputDecoration(
                labelText: 'Unit Cost (KM)',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                errorText: _isUnitCostInvalid
                    ? 'Enter a valid amount greater than 0'
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.isEmpty) return newValue;
                  final decimalPattern = RegExp(r'^\d{0,9}([.,]\d{0,2})?$');
                  return decimalPattern.hasMatch(text) ? newValue : oldValue;
                }),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  key: const Key('add_item_submit'),
                  onPressed:
                      _selectedProductId == null ||
                          _quantityController.text.isEmpty ||
                          _unitCostController.text.isEmpty ||
                          _isUnitCostInvalid ||
                          _stockInsufficient
                      ? null
                      : () {
                          final quantity = int.tryParse(
                            _quantityController.text,
                          );
                          final unitCost = _parsedUnitCost;
                          if (quantity == null || unitCost == null) {
                            return;
                          }
                          widget.onAdd({
                            'storeProductId': _selectedProductId!,
                            'productName': _selectedProductName!,
                            'quantity': quantity,
                            'unitCost': unitCost,
                          });
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
