import 'package:flutter/material.dart';
import 'package:shop/constants.dart';

import 'components/most_popular.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: MostPopular()),
          ],
        ),
      ),
    );
  }
}
