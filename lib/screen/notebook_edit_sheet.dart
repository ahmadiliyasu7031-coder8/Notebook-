import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../core/constants.dart';
import '../models/notebook.dart';

class NotebookEditSheet extends StatefulWidget {
  final Notebook notebook;

  const NotebookEditSheet({super.key, required this.notebook});

  @override
  State<NotebookEditSheet> createState() => _NotebookEditSheetState();
}

class _NotebookEditSheetState extends State<NotebookEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _subject;
  late final TextEditingController _school;
  late final TextEditingController _regNo;
  late int _coverColorIndex;
  late bool _isLocked;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.notebook.name);
    _subject = TextEditingController(text: widget.notebook.subject);
    _school = TextEditingController(text: widget.notebook.school);
    _regNo = TextEditingController(text: widget.notebook.regNo);
    _coverColorIndex = widget.notebook.coverColorIndex;
    _isLocked = widget.notebook.isLocked;
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  void _save() {
    String? passwordHash = widget.notebook.passwordHash;
    if (_isLocked && _pinController.text.trim().isNotEmpty) {
      passwordHash = _hash(_pinController.text.trim());
    }
    Navigator.of(context).pop(widget.notebook.copyWith(
      name: _name.text.trim(),
      subject: _subject.text.trim(),
      school: _school.text.trim(),
      regNo: _regNo.text.trim(),
      coverColorIndex: _coverColorIndex,
      isLocked: _isLocked,
      passwordHash: _isLocked ? passwordHash : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Notebook Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _school,
                decoration: const InputDecoration(labelText: 'School'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _regNo,
                decoration: const InputDecoration(labelText: 'Reg No'),
              ),
              const SizedBox(height: 16),
              const Text('Cover Color', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(AppColors.coverPalette.length, (i) {
                  final selected = i == _coverColorIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _coverColorIndex = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.coverPalette[i],
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black, width: 2.5) : null,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isLocked,
                title: const Text('Lock this notebook with a PIN'),
                onChanged: (v) => setState(() => _isLocked = v),
              ),
              if (_isLocked)
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: widget.notebook.passwordHash != null
                        ? 'New PIN (leave blank to keep current)'
                        : 'Set a PIN',
                    counterText: '',
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Save')),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
