import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/stores/widgets/add_store_product_dialog.dart';
import 'package:rs2_desktop/models/inventory/store_model.dart';
import 'package:rs2_desktop/models/inventory/store_product_model.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/routes/app_router.dart';

class StoreEditScreen extends StatefulWidget {
  final Store store;
  const StoreEditScreen({super.key, required this.store});

  @override
  State<StoreEditScreen> createState() => _StoreEditScreenState();
}

class _StoreEditScreenState extends State<StoreEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late bool _isExternal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _addressController = TextEditingController(text: widget.store.location ?? '');
    _phoneController = TextEditingController();
    _isExternal = widget.store.isExternal;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryProvider>().fetchStoreProducts(storeId: widget.store.id);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final success = await context.read<StoresProvider>().updateStore(
            widget.store.id,
            name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            isExternal: _isExternal,
          );
      if (!mounted) return;
      if (success) {
        _showSnackBar('Store updated successfully', AppColors.success);
        Navigator.pop(context);
      } else {
        final error = context.read<StoresProvider>().error;
        _showSnackBar(error ?? 'Failed to update store', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showDeleteProductDialog(StoreProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${product.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<InventoryProvider>().deleteStoreProduct(product.id);
              if (mounted) {
                _showSnackBar(
                  success ? 'Product deleted' : 'Failed to delete product',
                  success ? AppColors.success : AppColors.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit ${widget.store.name}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Store info card ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Store Information', Icons.store_outlined),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Store Name *',
                          hint: 'e.g. Main Warehouse',
                          icon: Icons.store_outlined,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address (optional)',
                          hint: 'e.g. 123 Main Street',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone (optional)',
                          hint: 'Leave empty to keep current',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('External supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text(
                                      _isExternal
                                          ? 'This is an external supplier (not your own location)'
                                          : 'This is your own internal store/warehouse',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isExternal,
                                onChanged: (v) => setState(() => _isExternal = v),
                                activeThumbColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _handleSave,
                              icon: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save),
                              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Store products card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSectionTitle('Store Products', Icons.inventory_2_outlined)),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final invProvider = context.read<InventoryProvider>();
                              await showDialog(
                                context: context,
                                builder: (_) => AddStoreProductDialog(
                                  store: widget.store,
                                  existingNames: invProvider.storeProducts
                                      .where((p) => p.storeId == widget.store.id)
                                      .map((p) => p.name.toLowerCase())
                                      .toSet(),
                                  onAdded: () => invProvider.fetchStoreProducts(storeId: widget.store.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Product'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Consumer<InventoryProvider>(
                        builder: (context, invProvider, _) {
                          if (invProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          }

                          final products = invProvider.storeProducts
                              .where((p) => p.storeId == widget.store.id)
                              .toList();

                          if (products.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No products yet. Add the first one.',
                                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: products.map((product) => _buildProductRow(product)).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(StoreProductModel product) {
    final isLow = product.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLow ? AppColors.warning.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isLow ? AppColors.warning : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: isLow ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    if (isLow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Low Stock', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.currentStock} / min ${product.minimumStock} ${product.unit}  ·  ${product.purchasePrice.toStringAsFixed(2)} KM',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () async {
              final invProvider = context.read<InventoryProvider>();
              await Navigator.pushNamed(
                context,
                AppRouter.adminStoreProductEdit,
                arguments: product,
              );
              if (!mounted) return;
              invProvider.fetchStoreProducts(storeId: widget.store.id);
            },
            tooltip: 'Edit',
            color: AppColors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _showDeleteProductDialog(product),
            tooltip: 'Delete',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          ),
        ),
      ],
    );
  }
}
