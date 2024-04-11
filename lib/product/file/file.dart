import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:taskwolf_app/product/base/page.dart';

class FilePage extends StatelessWidget {
  FilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductPage(name: Locales.string(context, "product.files.title"),
      content: Center());
  }
}