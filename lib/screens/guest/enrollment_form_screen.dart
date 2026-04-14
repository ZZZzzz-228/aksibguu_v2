import 'package:flutter/material.dart';

import '../../data/session/app_session.dart';

class EnrollmentFormScreen extends StatefulWidget {
  final String programTitle;
  final Color programColor;
  const EnrollmentFormScreen({super.key, required this.programTitle, required this.programColor});
  @override
  State<EnrollmentFormScreen> createState() => _EnrollmentFormScreenState();
}
class _EnrollmentFormScreenState extends State<EnrollmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messengerController = TextEditingController();
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  int _applicationId = 0;
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messengerController.dispose();
    super.dispose();
  }
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final id = await AppSession.apiClient.submitPublicApplication(
        type: 'courses',
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        payload: {
          'program_title': widget.programTitle,
          'preferred_messenger': _messengerController.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _applicationId = id;
        _isSubmitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Запись на обучение'),
        backgroundColor: widget.programColor,
        foregroundColor: Colors.white,
      ),
      body: _isSubmitted ? _buildSuccessView() : _buildFormView(),
    );
  }
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: widget.programColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_outline, color: widget.programColor, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Заявка отправлена!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'Спасибо за интерес к программе «${widget.programTitle}»!\n\nМы получили вашу заявку и свяжемся с вами в ближайшее время для уточнения деталей и подтверждения записи.\n\nОжидайте звонка или сообщения в выбранном вами мессенджере.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6),
            ),
            if (_applicationId > 0) ...[
              const SizedBox(height: 10),
              Text('Номер заявки: $_applicationId', style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.programColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Вернуться', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.programColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.programColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Icon(Icons.school, color: widget.programColor, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Программа: ${widget.programTitle}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.programColor))),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('ФИО', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Введите ваше ФИО',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, введите ФИО';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Телефон', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+7 (___) ___-__-__',
                prefixIcon: const Icon(Icons.phone_outlined),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, введите номер телефона';
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Мессенджер', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messengerController,
              decoration: InputDecoration(
                hintText: 'Telegram, WhatsApp, Viber и т.д.',
                prefixIcon: const Icon(Icons.chat_outlined),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.programColor, width: 2)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Пожалуйста, укажите мессенджер';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.programColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Отправить заявку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
