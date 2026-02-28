import 'package:flutter/material.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/duck_bond.dart';
import 'package:waddle/domain/entities/duck_companion.dart';

/// Renders wade_floating.png tinted with the duck's unique color.
///
/// Use [size] to control the image dimensions.
/// When [locked] is true, shows the locked egg icon instead.
/// When [bond] is provided, accessory overlays are rendered.
class DuckAvatar extends StatelessWidget {
  final DuckCompanion duck;
  final double size;
  final bool locked;
  final DuckBondData? bond;

  const DuckAvatar({
    super.key,
    required this.duck,
    this.size = 48,
    this.locked = false,
    this.bond,
  });

  /// Convenience: render a duck by its index from [DuckCompanions.all].
  factory DuckAvatar.fromIndex({
    Key? key,
    required int index,
    double size = 48,
    bool locked = false,
    DuckBondData? bond,
  }) {
    return DuckAvatar(
      key: key,
      duck: DuckCompanions.all[index],
      size: size,
      locked: locked,
      bond: bond,
    );
  }

  static const String _assetPath = 'lib/assets/images/wade_floating.png';

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(Icons.egg_rounded, size: size * 0.75, color: Colors.grey);
    }

    final duckImage = ColorFiltered(
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

    // No accessories — just the duck
    if (bond == null || bond!.equippedAccessories.isEmpty) {
      return duckImage;
    }

    // With accessory overlays
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          duckImage,
          ..._buildOverlays(),
        ],
      ),
    );
  }

  List<Widget> _buildOverlays() {
    final overlays = <Widget>[];
    final scale = size / 48.0; // base size reference

    // Overlay positions relative to size (fraction-based)
    const offsets = {
      AccessorySlot.hat: Offset(0.35, -0.15),
      AccessorySlot.eyewear: Offset(0.55, 0.22),
      AccessorySlot.neckwear: Offset(0.35, 0.60),
      AccessorySlot.held: Offset(0.80, 0.45),
    };

    for (final slot in AccessorySlot.values) {
      final accId = bond!.accessoryForSlot(slot);
      if (accId == null) continue;

      final accessory = DuckAccessories.byId(accId);
      if (accessory == null) continue;

      final offset = offsets[slot]!;
      final iconSize = 12.0 * scale;
      final containerSize = 16.0 * scale;

      overlays.add(
        Positioned(
          left: size * offset.dx - containerSize / 2,
          top: size * offset.dy - containerSize / 2,
          child: Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: accessory.color.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.0 * scale.clamp(0.5, 2.0),
              ),
            ),
            child: Icon(
              accessory.icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return overlays;
  }
}
