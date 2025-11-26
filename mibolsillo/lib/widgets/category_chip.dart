import 'package:flutter/material.dart';
import '../models/categoria.dart';

class CategoryChip extends StatelessWidget {
  final Categoria categoria;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.categoria, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(categoria.nombre),
        backgroundColor: selected ? Colors.redAccent : Colors.grey[200],
      ),
    );
  }
}
