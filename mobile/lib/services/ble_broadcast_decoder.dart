import 'dart:typed_data';

/// Result of decoding an OKOK manufacturer-data broadcast.
class BroadcastResult {
  final double weightKg;
  final double? impedance;
  final bool isStable;
  final bool isFinalBia;
  final String rawHex;
  final int companyId;

  const BroadcastResult({
    required this.weightKg,
    required this.impedance,
    required this.isStable,
    required this.isFinalBia,
    required this.rawHex,
    required this.companyId,
  });

  @override
  String toString() =>
      'BroadcastResult(weight=$weightKg kg, impedance=$impedance, '
      'stable=$isStable, finalBia=$isFinalBia)';
}

/// Decodes OKOK-style BLE manufacturer data broadcasts.
class BleBroadcastDecoder {
  BleBroadcastDecoder._();

  /// True when bytes 7–12 equal the MAC in [address] (`AA:BB:CC:DD:EE:FF`).
  static bool _tailMatchesMac(Uint8List data, String? address) {
    if (address == null) return false;
    final hex = address.replaceAll(':', '');
    if (hex.length != 12) return false;
    for (var i = 0; i < 6; i++) {
      final b = int.tryParse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      if (b == null || data[7 + i] != b) return false;
    }
    return true;
  }

  /// Decode a 13-byte OKOK broadcast payload.
  ///
  /// Two layouts share the same weight/impedance bytes:
  ///  * classic (F-6988 and similar): bytes 4–5 are `0a 01`;
  ///  * variant seen on "Yoda1" scales: bytes 4–5 are `00 00` and bytes 7–12
  ///    repeat the scale's own MAC address, e.g.
  ///    `35 89 13 88 00 00 25 80 f4 16 31 9a 8b` = 137.05 kg, 500.0 Ω.
  ///
  /// [deviceAddress] is the advertiser's MAC (`AA:BB:CC:DD:EE:FF`, as given
  /// by Android); the variant is only accepted when it matches, which keeps
  /// unrelated 13-byte manufacturer data from being read as a weight.
  ///
  /// Returns `null` when the data does not match either layout or the
  /// weight is outside the plausible 5–400 kg range.
  static BroadcastResult? decodeOkokBroadcast(
    int companyId,
    Uint8List byteData, {
    String? deviceAddress,
  }) {
    if (byteData.length != 13) return null;

    final classicMagic = byteData[4] == 0x0A && byteData[5] == 0x01;
    if (!classicMagic && !_tailMatchesMac(byteData, deviceAddress)) {
      return null;
    }

    // Weight
    final weightRaw = (byteData[0] << 8) | byteData[1];
    final weightKg = weightRaw / 100.0;
    if (weightKg < 5.0 || weightKg > 400.0) return null;

    // Impedance
    final impedanceRaw = (byteData[2] << 8) | byteData[3];
    final impedance = impedanceRaw > 0 ? impedanceRaw / 10.0 : 0.0;

    final isStable = impedance > 0.0 || byteData[6] > 0;
    final isFinalBia = impedance > 0.0;

    final rawHex = byteData
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return BroadcastResult(
      weightKg: weightKg,
      impedance: isFinalBia ? impedance : null,
      isStable: isStable,
      isFinalBia: isFinalBia,
      rawHex: rawHex,
      companyId: companyId,
    );
  }
}
