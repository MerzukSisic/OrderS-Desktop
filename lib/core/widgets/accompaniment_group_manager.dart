import 'package:flutter/material.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/products/accompaniment.dart';
import 'package:rs2_desktop/models/products/accompaniment_group.dart';

/// Desktop Widget for managing Accompaniment Groups
/// Used in Product Create/Edit screens
class AccompanimentGroupManager extends StatefulWidget {
  final List<AccompanimentGroup> initialGroups;
  final Function(List<AccompanimentGroup>) onGroupsChanged;

  const AccompanimentGroupManager({
    super.key,
    required this.initialGroups,
    required this.onGroupsChanged,
  });

  @override
  State<AccompanimentGroupManager> createState() => _AccompanimentGroupManagerState();
}

class _AccompanimentGroupManagerState extends State<AccompanimentGroupManager> {
  late List<AccompanimentGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.initialGroups);
  }

  void _addNewGroup() {
    setState(() {
      _groups.add(AccompanimentGroup(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        productId: '',
        selectionType: 'Multiple',
        isRequired: false,
        displayOrder: _groups.length,
        accompaniments: [],
        createdAt: DateTime.now(),
      ));
    });
    widget.onGroupsChanged(_groups);
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
    widget.onGroupsChanged(_groups);
  }

  void _updateGroup(int index, AccompanimentGroup updatedGroup) {
    setState(() {
      _groups[index] = updatedGroup;
    });
    widget.onGroupsChanged(_groups);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accompaniment Groups',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define customizable extras (e.g. milk options, toppings)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _addNewGroup,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add Group'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Groups list
          if (_groups.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No accompaniment groups yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Group" to create customizable options',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _AccompanimentGroupCard(
                  group: _groups[index],
                  onUpdate: (updatedGroup) => _updateGroup(index, updatedGroup),
                  onRemove: () => _removeGroup(index),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Card for individual accompaniment group
class _AccompanimentGroupCard extends StatefulWidget {
  final AccompanimentGroup group;
  final Function(AccompanimentGroup) onUpdate;
  final VoidCallback onRemove;

  const _AccompanimentGroupCard({
    required this.group,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_AccompanimentGroupCard> createState() => _AccompanimentGroupCardState();
}

class _AccompanimentGroupCardState extends State<_AccompanimentGroupCard> {
  late TextEditingController _nameController;
  late String _selectionType;
  late bool _isRequired;
  late int? _minSelections;
  late int? _maxSelections;
  late List<Accompaniment> _accompaniments;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _selectionType = widget.group.selectionType;
    _isRequired = widget.group.isRequired;
    _minSelections = widget.group.minSelections;
    _maxSelections = widget.group.maxSelections;
    _accompaniments = List.from(widget.group.accompaniments);

    _nameController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onUpdate(AccompanimentGroup(
      id: widget.group.id,
      name: _nameController.text,
      productId: widget.group.productId,
      selectionType: _selectionType,
      isRequired: _isRequired,
      minSelections: _minSelections,
      maxSelections: _maxSelections,
      displayOrder: widget.group.displayOrder,
      accompaniments: _accompaniments,
      createdAt: widget.group.createdAt,
    ));
  }

  void _addAccompaniment() {
    final newAccompaniment = Accompaniment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      accompanimentGroupId: widget.group.id,
      name: '',
      extraCharge: 0.0,
      isAvailable: true,
      displayOrder: _accompaniments.length,
      createdAt: DateTime.now(),
    );

    setState(() {
      _accompaniments.add(newAccompaniment);
      _notifyChanges();
    });
  }

  void _removeAccompaniment(int index) {
    setState(() {
      _accompaniments.removeAt(index);
      _notifyChanges();
    });
  }

  void _updateAccompaniment(int index, Accompaniment updated) {
    setState(() {
      _accompaniments[index] = updated;
      _notifyChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isExpanded ? Icons.expand_more : Icons.chevron_right,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'New Accompaniment Group'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_accompaniments.isNotEmpty)
                            Text(
                              '${_accompaniments.length} option${_accompaniments.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_accompaniments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_accompaniments.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      tooltip: 'Remove Group',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Configuration Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column - Name & Type
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Group Name *'),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'e.g. Milk Type, Toppings, Sides',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('Selection Type'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectionType,
                                  isExpanded: true,
                                  dropdownColor: AppColors.surfaceVariant,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Single',
                                      child: Text('Single Choice (radio)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Multiple',
                                      child: Text('Multiple Choice (checkbox)'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectionType = value!;
                                      _notifyChanges();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Right Column - Options
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              value: _isRequired,
                              onChanged: (value) {
                                setState(() {
                                  _isRequired = value ?? false;
                                  _notifyChanges();
                                });
                              },
                              title: const Text(
                                'Required Selection',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Min Selections'),
                            TextFormField(
                              initialValue: _minSelections?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _minSelections = int.tryParse(value);
                                  _notifyChanges();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Max Selections'),
                            TextFormField(
                              initialValue: _maxSelections?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'No limit',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _maxSelections = int.tryParse(value);
                                  _notifyChanges();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Accompaniments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('Accompaniment Options'),
                      TextButton.icon(
                        onPressed: _addAccompaniment,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Option'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Accompaniments Grid
                  if (_accompaniments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No options added yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _accompaniments.length,
                      itemBuilder: (context, index) {
                        return _AccompanimentItem(
                          accompaniment: _accompaniments[index],
                          onUpdate: (updated) => _updateAccompaniment(index, updated),
                          onRemove: () => _removeAccompaniment(index),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Individual accompaniment item
class _AccompanimentItem extends StatefulWidget {
  final Accompaniment accompaniment;
  final Function(Accompaniment) onUpdate;
  final VoidCallback onRemove;

  const _AccompanimentItem({
    required this.accompaniment,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_AccompanimentItem> createState() => _AccompanimentItemState();
}

class _AccompanimentItemState extends State<_AccompanimentItem> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accompaniment.name);
    _priceController = TextEditingController(
      text: widget.accompaniment.extraCharge > 0
          ? widget.accompaniment.extraCharge.toStringAsFixed(2)
          : '',
    );

    _nameController.addListener(_notifyChanges);
    _priceController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onUpdate(Accompaniment(
      id: widget.accompaniment.id,
      accompanimentGroupId: widget.accompaniment.accompanimentGroupId,
      name: _nameController.text,
      extraCharge: double.tryParse(_priceController.text) ?? 0.0,
      isAvailable: widget.accompaniment.isAvailable,
      displayOrder: widget.accompaniment.displayOrder,
      createdAt: widget.accompaniment.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Name field
          Expanded(
            child: TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Price field
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                suffixText: ' KM',
                suffixStyle: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),

          // Remove button
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}