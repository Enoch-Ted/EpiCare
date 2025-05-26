// lib/features/settings/screens/skin_info_menu_screen.dart
import 'package:care/core/navigation/app_router.dart'; // Adjust import path
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkinInfoMenuScreen extends StatelessWidget {
  const SkinInfoMenuScreen({Key? key}) : super(key: key);

  // Helper to build section headers (copy-pasted from SettingsScreen for consistency)
  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Cancer Information'),
      ),
      body: ListView(
        children: [
          // --- Section 1: SKIN CANCER ---
          _buildSectionHeader("Skin Cancer", context),
          ListTile(
            title: const Text("Basal Cell Carcinoma"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            // Navigate to the generic content page, passing the title
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Basal Cell Carcinoma'),
          ),
          ListTile(
            title: const Text("Squamous Cell Carcinoma"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Squamous Cell Carcinoma'),
          ),
          ListTile(
            title: const Text("Melanoma"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Melanoma'),
          ),
          ListTile(
            title: const Text("Symptoms of Suspicious Moles"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Symptoms of Suspicious Moles'),
          ),
          const Divider(height: 1), // Optional divider between sections

          // --- Section 2: SKINSPOTS ---
          _buildSectionHeader("Skin Spots", context),
          ListTile(
            title: const Text("Actinic Keratosis"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Actinic Keratosis'),
          ),
          ListTile(
            title: const Text("Age Warts"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Age Warts'),
          ),
          ListTile(
            title: const Text("Angiomas"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Angiomas'),
          ),
          ListTile(
            title: const Text("Light and Dark Pigmented Spots"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Light and Dark Pigmented Spots'),
          ),
          ListTile(
            title: const Text("Normal and Atypical Moles"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Normal and Atypical Moles'),
          ),
          const Divider(height: 1), // Optional divider between sections

          // --- Section 3: SKIN CONDITIONS ---
          _buildSectionHeader("Skin Conditions", context),
          ListTile(
            title: const Text("Acne"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Acne'),
          ),
          ListTile(
            title: const Text("Blisters"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Blisters'),
          ),
          ListTile(
            title: const Text("Dermatofibroma"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Dermatofibroma'),
          ),
          ListTile(
            title: const Text("Pityriasis"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Pityriasis'),
          ),
          ListTile(
            title: const Text("Sun Allergy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(AppRoutes.settingsGenericContent, extra: 'Sun Allergy'),
          ),
          const SizedBox(height: 16), // Padding at the bottom
        ],
      ),
    );
  }
}