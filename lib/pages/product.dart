import 'package:flutter/material.dart';
import '../product_manager.dart';

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Product Detail'),
        ),
        body: Center(
          child: Text('On the Product Page'),
        )
      );
  }
}