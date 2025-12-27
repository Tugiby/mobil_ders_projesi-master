import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<UserEntity> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await widget.repository.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserRole(UserEntity user) async {
    final newRole = user.role == UserRole.admin
        ? UserRole.user
        : UserRole.admin;

    try {
      await widget.repository.updateUserRole(user.id, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.name} ${newRole == UserRole.admin ? "admin yapıldı" : "kullanıcı yapıldı"}',
          ),
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hata: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUsers,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _users.isEmpty
          ? const Center(child: Text('Kullanıcı bulunamadı'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.role == UserRole.admin
                          ? Colors.purple
                          : Colors.blue,
                      child: Icon(
                        user.role == UserRole.admin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text(user.unit, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: user.role == UserRole.admin
                            ? Colors.purple.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.role == UserRole.admin ? 'Admin' : 'Kullanıcı',
                        style: TextStyle(
                          color: user.role == UserRole.admin
                              ? Colors.purple
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => _showUserDialog(user),
                  ),
                );
              },
            ),
    );
  }

  void _showUserDialog(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Birim: ${user.unit}'),
            const SizedBox(height: 8),
            Text('Rol: ${user.role == UserRole.admin ? "Admin" : "Kullanıcı"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _toggleUserRole(user);
            },
            icon: Icon(
              user.role == UserRole.admin
                  ? Icons.person
                  : Icons.admin_panel_settings,
            ),
            label: Text(
              user.role == UserRole.admin ? 'Kullanıcı Yap' : 'Admin Yap',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.role == UserRole.admin
                  ? Colors.blue
                  : Colors.purple,
            ),
          ),
        ],
      ),
    );
  }
}
