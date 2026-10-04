import 'package:flutter/material.dart';
import 'package:taskwolf/product/base/header.dart';
import 'package:taskwolf/product/base/sidebar.dart';

class ProductPage extends StatelessWidget {
  ProductPage({super.key, required this.name, required this.content});

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