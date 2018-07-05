import 'package:flutter/material.dart';

class TitleDefault extends StatelessWidget {
  final String productTitle;

  TitleDefault(this.productTitle);

  @override
  Widget build(BuildContext context) {
    return Text(
      productTitle,
      style: TextStyle(
        fontSize: 26.0,
        fontFamily: 'Oswald',
      ),
    );
  }
}
