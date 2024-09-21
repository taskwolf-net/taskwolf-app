import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:dulno_app/product/base/header.dart';
import 'package:dulno_app/product/file/file-delete-history.dart';
import 'package:dulno_app/product/file/file-info-history.dart';
import 'package:dulno_app/product/file/file-storage-history.dart';

class FileHistoryPage extends StatelessWidget {
  FileHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductHeader(page: Locales.string(context, "product.files.history")),
      body: Container(
        alignment: Alignment.center,
        child: OverflowBar(
          alignment: MainAxisAlignment.spaceEvenly,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            createFileHistoryButton(Icons.storage,
              "product.files.storage.history",
              FileStorageHistoryPage(), context),
            createFileHistoryButton(
              Icons.upload, "product.files.info.history",
              FileInfoHistoryPage(), context),
            createFileHistoryButton(
              Icons.delete, "product.files.delete.history",
              FileDeleteHistoryPage(), context),
          ],
        )
      )
    );
  }

  createFileHistoryButton(icon, text, page, context) {
    return Container(
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        child: Container(
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 80,),
                SizedBox(height: 10),
                LocaleText(text, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25))
              ],
            )
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0))
        ),
        onPressed: () async {
          Navigator.push(context,
            MaterialPageRoute(builder: (context) => page));
        },
      )
    );
  }
}