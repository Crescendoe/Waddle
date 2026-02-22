import 'package:flutter/material.dart';
import 'package:waddle/domain/entities/duck_companion.dart';

/// Renders wade_floating.png tinted with the duck's unique color.
///
/// Use [size] to control the image dimensions.
/// When [locked] is true, shows the locked egg icon instead.
class DuckAvatar extends StatelessWidget {
  final DuckCompanion duck;
  final double size;
  final bool locked;

  const DuckAvatar({
    super.key,
    required this.duck,
    this.size = 48,
    this.locked = false,
  });

  /// Convenience: render a duck by its index from [DuckCompanions.all].
  factory DuckAvatar.fromIndex({
    Key? key,
    required int index,
    double size = 48,
    bool locked = false,
  }) {
    return DuckAvatar(
      key: key,
      duck: DuckCompanions.all[index],
      size: size,
      locked: locked,
    );
  }

  static const String _assetPath = 'lib/assets/images/wade_floating.png';

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(Icons.egg_rounded, size: size * 0.75, color: Colors.grey);
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        duck.tintColor.withValues(alpha: 0.55),
        BlendMode.srcATop,
      ),
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
