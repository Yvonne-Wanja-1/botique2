import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/repositories/commerce_repository.dart';
import '../../models/promotion.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  late Future<List<Promotion>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PromotionRepository>().getAll();
  }

  Future<void> _reload() async {
    final f = context.read<PromotionRepository>().getAll();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(child: Text('Create and manage store promotions.')),
              ElevatedButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add),
                label: const Text('New Promotion'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Promotion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              }
              final promotions = snapshot.data ?? [];
              if (promotions.isEmpty) {
                return const Center(child: Text('No promotions yet'));
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: promotions.length,
                  itemBuilder: (context, index) {
                    final p = promotions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: QueensTouchColors.blushLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    p.code,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: QueensTouchColors.plum, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (p.description != null && p.description!.isNotEmpty)
                                        Text(
                                          p.description!,
                                          style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        '${p.isPercentage ? '${p.value.round()}% off' : '${formatKsh(p.value)} off'}'
                                        '${p.minimumOrderAmount != null ? ' · min ${formatKsh(p.minimumOrderAmount!)}' : ''}'
                                        '${p.usageLimit != null ? ' · ${p.usageCount}/${p.usageLimit} used' : ' · ${p.usageCount} used'}',
                                        style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: p.isActive,
                                  onChanged: (v) => _toggleActive(p, v),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) => _handleMenu(action, p),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'usage', child: Text('View Usage')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: QueensTouchColors.danger))),
                                  ],
                                ),
                              ],
                            ),
                            if (p.startDate != null || p.endDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Valid: ${p.startDate != null ? _fmtDate(p.startDate!) : 'No start'} → ${p.endDate != null ? _fmtDate(p.endDate!) : 'No end'}',
                                  style: const TextStyle(fontSize: 11, color: QueensTouchColors.textMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _toggleActive(Promotion p, bool value) async {
    final repo = context.read<PromotionRepository>();
    try {
      await repo.update(p.copyWith(isActive: value));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, 'Failed to update: $e');
    }
  }

  void _handleMenu(String action, Promotion p) {
    switch (action) {
      case 'edit':
        _openForm(context, existing: p);
      case 'usage':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(p.code),
            content: Text('Used ${p.usageCount} times${p.usageLimit != null ? ' of ${p.usageLimit}' : ''}.'),
          ),
        );
      case 'delete':
        _deletePromotion(p);
    }
  }

  Future<void> _deletePromotion(Promotion p) async {
    final ok = await confirmDialog(context, title: 'Delete promotion?', message: '${p.code} will be removed.', isDanger: true);
    if (!ok) return;
    try {
      await context.read<PromotionRepository>().delete(p.id);
      await _reload();
      if (mounted) showSuccessSnack(context, 'Promotion deleted');
    } catch (e) {
      if (mounted) showErrorSnack(context, 'Failed to delete: $e');
    }
  }

  void _openForm(BuildContext context, {Promotion? existing}) async {
    final result = await showModalBottomSheet<Promotion>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _PromotionForm(existing: existing),
      ),
    );
    if (!mounted || result == null) return;
    final repo = context.read<PromotionRepository>();
    try {
      if (existing != null) {
        await repo.update(result.copyWith(id: existing.id));
        if (mounted) showSuccessSnack(context, 'Promotion updated');
      } else {
        await repo.create(result);
        if (mounted) showSuccessSnack(context, 'Promotion "${result.code}" created');
      }
      _reload();
    } catch (e) {
      if (mounted) showSuccessSnack(context, 'Failed: $e');
    }
  }
}

class _PromotionForm extends StatefulWidget {
  const _PromotionForm({this.existing});
  final Promotion? existing;

  @override
  State<_PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<_PromotionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _usageLimit;
  late bool _isPercentage;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.code ?? '');
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _value = TextEditingController(text: e != null ? (e.value == e.value.roundToDouble() ? e.value.toInt().toString() : e.value.toString()) : '');
    _minOrder = TextEditingController(text: e?.minimumOrderAmount?.toInt().toString() ?? '');
    _maxDiscount = TextEditingController(text: e?.maximumDiscount?.toInt().toString() ?? '');
    _usageLimit = TextEditingController(text: e?.usageLimit?.toString() ?? '');
    _isPercentage = e?.type == PromotionType.percentage || e == null;
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _description.dispose();
    _value.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    _usageLimit.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 30))),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final val = double.tryParse(_value.text.trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid discount value')));
      return;
    }
    if (_isPercentage && val > 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Percentage cannot exceed 100')));
      return;
    }
    final promo = Promotion(
      id: widget.existing?.id ?? 'promo-${DateTime.now().millisecondsSinceEpoch}',
      code: _code.text.trim().toUpperCase(),
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      type: _isPercentage ? PromotionType.percentage : PromotionType.fixed,
      value: val,
      minimumOrderAmount: double.tryParse(_minOrder.text.trim()),
      maximumDiscount: double.tryParse(_maxDiscount.text.trim()),
      usageLimit: int.tryParse(_usageLimit.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.existing?.isActive ?? true,
    );
    Navigator.pop(context, promo);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEditing ? 'Edit Promotion' : 'New Promotion',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Promo code *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Percentage')),
                ButtonSegment(value: false, label: Text('Fixed')),
              ],
              selected: {_isPercentage},
              onSelectionChanged: (s) => setState(() => _isPercentage = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _isPercentage ? 'Discount % *' : 'Discount amount *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minimum order amount'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxDiscount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Maximum discount cap'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usageLimit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Usage limit'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate != null ? 'Start: ${_fmtDate(_startDate!)}' : 'Start date'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate != null ? 'End: ${_fmtDate(_endDate!)}' : 'End date'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
