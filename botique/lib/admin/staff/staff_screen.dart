import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/repositories/user_repository.dart';
import '../../models/user.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<User> _staff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<UserRepository>();
      _staff = await repo.list();
    } catch (_) {
      _staff = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manage staff accounts, roles and access.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addStaff(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Staff'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _staff.isEmpty
                  ? const Center(child: Text('No staff members found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _staff.length,
                        itemBuilder: (context, index) {
                          final staff = _staff[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: QueensTouchColors.blushLight,
                                child: Text(
                                  staff.name.isNotEmpty ? staff.name[0] : '?',
                                  style: const TextStyle(color: QueensTouchColors.plum),
                                ),
                              ),
                              title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${staff.email} · ${staff.role.label}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'role') _changeRole(context, staff);
                                  if (v == 'deactivate') _deactivate(context, staff);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'role', child: Text('Change role')),
                                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate account')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  void _addStaff(BuildContext context) {
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
        child: _NewStaffForm(onCreate: (user) {
          setState(() => _staff.add(user));
        }),
      ),
    );
  }

  void _changeRole(BuildContext context, User staff) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Change role for ${staff.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            for (final role in [Role.storeManager, Role.salesStaff, Role.inventoryStaff])
              ListTile(
                title: Text(role.label),
                trailing: staff.role == role ? const Icon(Icons.check, color: QueensTouchColors.plum) : null,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final repo = context.read<UserRepository>();
                    final updated = await repo.setRole(staff.id, role.apiValue);
                    setState(() {
                      final idx = _staff.indexWhere((s) => s.id == staff.id);
                      if (idx >= 0) _staff[idx] = updated;
                    });
                    if (context.mounted) showSuccessSnack(context, 'Role updated to ${role.label}');
                  } catch (e) {
                    if (context.mounted) showSuccessSnack(context, 'Failed to update role');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deactivate(BuildContext context, User staff) async {
    final ok = await confirmDialog(
      context,
      title: 'Deactivate account?',
      message: '${staff.name} will lose access immediately.',
      isDanger: true,
    );
    if (ok) {
      try {
        final repo = context.read<UserRepository>();
        await repo.setActive(staff.id, false);
        setState(() => _staff = _staff.where((s) => s.id != staff.id).toList());
      } catch (_) {}
      if (!context.mounted) return;
      showSuccessSnack(context, '${staff.name} deactivated');
    }
  }
}

class _NewStaffForm extends StatefulWidget {
  const _NewStaffForm({required this.onCreate});

  final ValueChanged<User> onCreate;

  @override
  State<_NewStaffForm> createState() => _NewStaffFormState();
}

class _NewStaffFormState extends State<_NewStaffForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  Role _role = Role.salesStaff;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add Staff', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 12),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 12),
        TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        const SizedBox(height: 12),
        DropdownButtonFormField<Role>(
          initialValue: _role,
          decoration: const InputDecoration(labelText: 'Role'),
          items: [
            for (final role in [Role.storeManager, Role.salesStaff, Role.inventoryStaff])
              DropdownMenuItem(value: role, child: Text(role.label)),
          ],
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            if (_name.text.trim().isEmpty || _password.text.length < 8) return;
            try {
              final repo = context.read<UserRepository>();
              final user = await repo.create(
                email: _email.text.trim().isEmpty
                    ? '${_name.text.trim().toLowerCase().replaceAll(' ', '.')}@queenstouch.com'
                    : _email.text.trim(),
                password: _password.text,
                fullName: _name.text.trim(),
                phone: _phone.text.trim(),
                role: _role.apiValue,
              );
              widget.onCreate(user);
              Navigator.pop(context);
              if (context.mounted) showSuccessSnack(context, 'Staff account created');
            } catch (e) {
              if (context.mounted) showSuccessSnack(context, 'Failed to create staff account');
            }
          },
          child: const Text('Create Account'),
        ),
      ],
    );
  }
}
