import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/session/app_session.dart';

class DocumentSubmissionScreen extends StatefulWidget {
  final List<String>? initialSpecialties;

  // Keep old single-specialty param for backward compatibility
  final String? initialSpecialty;

  const DocumentSubmissionScreen({
    super.key,
    this.initialSpecialties,
    this.initialSpecialty,
  });

  @override
  State<DocumentSubmissionScreen> createState() =>
      _DocumentSubmissionScreenState();
}

class _DocumentSubmissionScreenState
    extends State<DocumentSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final Set<String> _selectedSpecialties = {};
  final List<PlatformFile> _attachedFiles = [];
  bool _isPickingFiles = false;
  bool _isSubmitting = false;
  int _applicationId = 0;
  bool _submitted = false;

  static const List<String> _allSpecialties = [
    'Сетевое и системное администрирование',
    'Информационные системы и программирование',
    'Обеспечение информационной безопасности телекоммуникационных систем',
    'Обеспечение информационной безопасности автоматизированных систем',
    'Техническая эксплуатация и обслуживание электрического и электромеханического оборудования (по отраслям)',
    'Специальные машины и устройства',
    'Технология машиностроения',
    'Мехатроника и мобильная робототехника (по отраслям)',
    'Сооружение и эксплуатация газонефтепроводов и газонефтехранилищ (прикладная геология, горное дело, нефтегазовое дело и геодезия)',
    'Сварочное производство',
    'Техническое обслуживание авиационных двигателей',
    'Контроль работы измерительных приборов',
    'Электро- и теплоэнергетика',
    'Аэронавигация и эксплуатация авиационной и ракетно-космической техники',
    'Экономика и бухгалтерский учет',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select specialties
    if (widget.initialSpecialties != null) {
      _selectedSpecialties.addAll(widget.initialSpecialties!);
    }
    if (widget.initialSpecialty != null &&
        widget.initialSpecialty!.isNotEmpty) {
      _selectedSpecialties.add(widget.initialSpecialty!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Открыть file_picker для выбора файлов ───────────────────────────────
  Future<void> _pickFiles() async {
    if (_isPickingFiles) return;
    _isPickingFiles = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && file.path!.isNotEmpty) {
              _attachedFiles.add(file);
            }
          }
        });
      }
    } on PlatformException catch (e) {
      // iOS/Android can throw "multiple_request" on rapid repeated taps.
      if (e.code == 'multiple_request') {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файла: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файла: $e')),
        );
      }
    } finally {
      _isPickingFiles = false;
    }
  }

  // ── Скопировать PDF из assets во временную папку и открыть ───────────────
  Future<void> _openPdfFromAssets(String assetPath) async {
    try {
      // Читаем файл из assets
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Получаем временную директорию
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      // Записываем файл
      await tempFile.writeAsBytes(bytes, flush: true);

      // Открываем файл через системное приложение
      await OpenFile.open(tempFile.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось открыть файл. Убедитесь, что файл $assetPath добавлен в assets/docs/',
            ),
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _attachedFiles.removeAt(index));
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите ФИО')),
      );
      return;
    }
    if (_selectedSpecialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну специальность')),
      );
      return;
    }
    if (_attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Прикрепите хотя бы один документ')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final names = _attachedFiles.map((f) => f.name).toList(growable: false);
      final id = await AppSession.apiClient.submitPublicApplication(
        type: 'documents',
        fullName: name,
        email: email.isEmpty ? null : email,
        phone: phone.isEmpty ? null : phone,
        payload: {
          'specialties': _selectedSpecialties.toList(growable: false),
          'attached_file_names': names,
        },
        files: _attachedFiles,
      );
      if (!mounted) return;
      setState(() {
        _applicationId = id;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessScreen(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Подача документов'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Заполните форму и прикрепите необходимые документы для поступления',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Deadline banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Приём документов до 15 августа 2025',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── PERSONAL DATA ─────────────────────────────────────────
              const Text('ФИО',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Иванов Иван Иванович'),
              ),
              const SizedBox(height: 16),

              const Text('Электронная почта',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('example@mail.ru'),
              ),
              const SizedBox(height: 16),

              const Text('Телефон',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('+7 (999) 123-45-67'),
              ),
              const SizedBox(height: 24),

              // ── SPECIALTIES ───────────────────────────────────────────
              const Text('Специальности',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Выберите одну или несколько',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _allSpecialties.map((spec) {
                    final checked =
                    _selectedSpecialties.contains(spec);
                    return CheckboxListTile(
                      dense: true,
                      title: Text(spec,
                          style: const TextStyle(fontSize: 13)),
                      value: checked,
                      activeColor: const Color(0xFF4A90E2),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedSpecialties.add(spec);
                          } else {
                            _selectedSpecialties.remove(spec);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // ── REQUIRED DOCS INFO ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD600)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFF9A825), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Необходимые документы',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _docItem('Паспорт (копия)'),
                    _docItem('Аттестат об образовании (оригинал/копия)'),
                    _docItem('Медицинская справка 086-У'),
                    _docItem('6 фотографий 3×4'),
                    _docItem('СНИЛС (копия)'),
                    _docItem('Заявление (скачайте бланк ниже)'),
                    _docItem('Согласие на обработку персональных данных'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── PDF DOWNLOADS ─────────────────────────────────────────
              const Text('Бланки для скачивания',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _buildPdfButton(
                'Заявление о приёме',
                'assets/docs/zayavlenie.pdf',
                const Color(0xFF4A90E2),
                Icons.description,
              ),
              const SizedBox(height: 8),
              _buildPdfButton(
                'Согласие на обработку ПД',
                'assets/docs/soglasie.pdf',
                const Color(0xFF7B68EE),
                Icons.privacy_tip,
              ),
              const SizedBox(height: 24),

              // ── FILE UPLOAD ───────────────────────────────────────────
              const Text('Прикрепите сканы документов',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),

              // Attached files list
              if (_attachedFiles.isNotEmpty) ...[
                ...List.generate(_attachedFiles.length, (i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF4CAF50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file,
                            color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_attachedFiles[i].name,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        GestureDetector(
                          onTap: () => _removeFile(i),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 18),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              // Add file button — теперь открывает file_picker
              GestureDetector(
                onTap: _isPickingFiles ? null : _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey[400]!, width: 2,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 44, color: Colors.grey[500]),
                      const SizedBox(height: 10),
                      Text(
                        _isPickingFiles
                            ? 'Открываем выбор файлов...'
                            : _attachedFiles.isEmpty
                            ? 'Нажмите, чтобы прикрепить файлы'
                            : 'Прикрепить ещё',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text('PDF, JPG, PNG (до 5 МБ)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── SUBMIT BUTTON ─────────────────────────────────────────
              AnimatedOpacity(
                opacity: _attachedFiles.isNotEmpty ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed:
                  (_attachedFiles.isNotEmpty && !_isSubmitting) ? _submit : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Отправка...' : 'Подать документы'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    disabledBackgroundColor:
                    const Color(0xFF4A90E2).withOpacity(0.4),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (_attachedFiles.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Прикрепите хотя бы один документ',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── SUCCESS SCREEN ──────────────────────────────────────────────────────────
  Widget _buildSuccessScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Подача документов'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Документы отправлены!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ваши документы будут рассмотрены в течение 3–5 рабочих дней. Ожидайте звонка или письма от приёмной комиссии.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.black54, height: 1.6),
              ),
              if (_applicationId > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Номер заявки: $_applicationId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(
                    context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('На главную',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A90E2))),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _docItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfButton(
      String label, String assetPath, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _openPdfFromAssets(assetPath),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ),
            Icon(Icons.download, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}