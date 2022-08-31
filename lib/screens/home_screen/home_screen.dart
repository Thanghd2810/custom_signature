import 'package:flutter/material.dart';

import '../../widget/handwritten.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Title(
          color: Colors.red,
          child: const Text("Test canvas"),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            SizedBox(
              height: 300,
              child: Handwritten(
                initImgPath: "",
              ),
            )
          ],
        ),
      ),
    );
  }
}
