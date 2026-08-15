import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../models/promotion.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final List<Promotion> _promotions = [
    const Promotion(
      id: 'promo1',
      code: 'QUEEN10',
      title: 'Welcome 10% Off',
      type: PromotionType.percentage,
      value: 10,
      minimumOrderAmount: 50,
      usageCount: 342,
      usageLimit: 500,
      isActive: true,
    ),
    const Promotion(
      id: 'promo2',
      code: 'ROYAL20',
      title: 'Royal 20% Off',
      type: PromotionType.percentage,
      value: 20,
      minimumOrderAmount: 100,
      maximumDiscount: 50,
      usageCount: 128,
      isActive: true,
    ),
    const Promotion(
      id: 'promo3',
      code: 'FLAT15',
      title: 'Flat 15 Off',
      type: PromotionType.fixed,
      value: 15,
      minimumOrderAmount: 75,
      usageCount: 210,
      isActive: false,
    ),
    const Promotion(
      id: 'promo4',
      code: 'SUMMER25',
      title: 'Summer Sale 25%',
      type: PromotionType.percentage,
      value: 25,
      minimumOrderAmount: 150,
      maximumDiscount: 75,
      usageCount: 0,
      usageLimit: 1000,
      startDate: null,
      endDate: null,
      isActive: true,
    ),
  ];

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
                onPressed: () => _createPromotion(context),
                icon: const Icon(Icons.add),
                label: const Text('New Promotion'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final p = _promotions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: QueensTouchColors.blushLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            p.code,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: QueensTouchColors.plum, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${p.isPercentage ? '${p.value.round()}% off' : '\$${p.value.toStringAsFixed(2)} off'}'
                              '${p.minimumOrderAmount != null ? ' · min \$${p.minimumOrderAmount!.round()}' : ''}'
                              '${p.usageLimit != null ? ' · ${p.usageCount}/${p.usageLimit} used' : ' · ${p.usageCount} used'}',
                              style: const TextStyle(fontSize: 12, color: QueensTouchColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: p.isActive,
                        onChanged: (v) => setState(() {}),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showMenu(context, p),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMenu(BuildContext context, Promotion p) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                showSuccessSnack(context, 'Edit coming with backend');
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('View Usage'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(p.code),
                    content: Text(
                      'Used ${p.usageCount} times${p.usageLimit != null ? ' of ${p.usageLimit}' : ''}.',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: QueensTouchColors.danger),
              title: const Text('Delete', style: TextStyle(color: QueensTouchColors.danger)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await confirmDialog(context, title: 'Delete promotion?', message: '${p.code} will be removed.', isDanger: true);
                if (ok) {
                  setState(() => _promotions.removeWhere((x) => x.id == p.id));
                  showSuccessSnack(context, 'Promotion deleted');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createPromotion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: const _NewPromotionForm(),
      ),
    );
  }
}

class _NewPromotionForm extends StatefulWidget {
  const _NewPromotionForm();

  @override
  State<_NewPromotionForm> createState() => _NewPromotionFormState();
}

class _NewPromotionFormState extends State<_NewPromotionForm> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _value = TextEditingController();
  bool _isPercentage = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New Promotion', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _code, decoration: const InputDecoration(labelText: 'Promo code')),
        const SizedBox(height: 12),
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
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
        TextField(
          controller: _value,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: _isPercentage ? 'Discount %' : 'Discount amount'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            showSuccessSnack(context, 'Promotion created (demo)');
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}