import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  bool _isLoading = false;
  String? _message;

  Future<void> _makeAdmin() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = 'Önce giriş yapın.';
          _isLoading = false;
        });
        return;
      }

      final usersRef = FirebaseFirestore.instance.collection('users');
      final docRef = usersRef.doc(user.uid);

      await docRef.set({
        'role': 'admin',
        // Yardımcı alanlar — mevcutsa üstüne yazmaz (merge: true)
        'email': user.email,
        'displayName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    } catch (e) {
      setState(() {
        _message = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Kurulumu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bu sayfa mevcut oturumdaki kullanıcıyı admin yapar.\nGiriş yaptığınız hesaba admin rolü atanacaktır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _makeAdmin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Admin Yap', style: TextStyle(fontSize: 16)),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message!.startsWith('Başarılı')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _message!.startsWith('Başarılı')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('Başarılı')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
