import 'package:flutter/material.dart';
import 'package:taskwolf/settings/base/header.dart';
import 'package:taskwolf/settings/base/sidebar.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key, required this.name, required this.content});

  final name;
  final content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductHeader(page: name),
      body: content,
      drawer: ProductSidebar(page: name)
    );
  }
}