import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppInfo.appName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppInfo.appTagline,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 28),
          const Text('About this app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            AppInfo.aboutText,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 28),
          const Text('Developer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(AppInfo.developerCredit, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Text('BSc Software Engineering — Federal University of Technology Babura',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _open(AppInfo.whatsappContactUrl),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contact Developer via WhatsApp'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(AppInfo.whatsappChannelUrl),
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Join our WhatsApp Channel'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
