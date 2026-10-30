import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_broadcast_decoder.dart';
import 'ble_constants.dart';
import 'ble_protocol_decoder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum BleStatus { idle, scanning, found, measuring, stable, complete, error }

class BleState {
  final BleStatus status;
  final double? weightKg;
  final int? impedance;
  final bool isStable;
  final bool isFinalBia;
  final String? deviceName;
  final String? errorMessage;

  const BleState({
    this.status = BleStatus.idle,
    this.weightKg,
    this.impedance,
    this.isStable = false,
    this.isFinalBia = false,
    this.deviceName,
    this.errorMessage,
  });

  BleState copyWith({
    BleStatus? status,
    double? weightKg,
    int? impedance,
    bool? isStable,
    bool? isFinalBia,
    String? deviceName,
    String? errorMessage,
  }) {
    return BleState(
      status: status ?? this.status,
      weightKg: weightKg ?? this.weightKg,
      impedance: impedance ?? this.impedance,
      isStable: isStable ?? this.isStable,
      isFinalBia: isFinalBia ?? this.isFinalBia,
      deviceName: deviceName ?? this.deviceName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'BleState($status, weight=$weightKg, impedance=$impedance, '
      'stable=$isStable, bia=$isFinalBia, device=$deviceName)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class BleService {
  final _stateController = StreamController<BleState>.broadcast();
  Stream<BleState> get stateStream => _stateController.stream;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  List<StreamSubscription<List<int>>>? _charSubscriptions;

  BluetoothDevice? _connectedDevice;
  BleState _currentState = const BleState();

  // ── Public API ─────────────────────────────────────────────────────────

  static const scanTimeout = Duration(seconds: 30);

  /// Start scanning for compatible Chipsea / OKOK scales.
  Future<void> startScan() async {
    try {
      // Check adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _emit(const BleState(
          status: BleStatus.error,
          errorMessage: 'Bluetooth is not enabled.',
        ));
        return;
      }

      _emit(const BleState(status: BleStatus.scanning));

      // Stop any ongoing scan
      await FlutterBluePlus.stopScan();

      // Listen to scan results
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        _onScanResults,
        onError: (Object error) {
          debugPrint('BleService scan error: $error');
          _emit(BleState(
            status: BleStatus.error,
            errorMessage: error.toString(),
          ));
        },
      );

      // When the scan stops on its own (timeout) and nothing was found,
      // leave the "step on the scale" state instead of hanging forever.
      _isScanningSubscription?.cancel();
      _isScanningSubscription = FlutterBluePlus.isScanning.skip(1).listen((scanning) {
        if (!scanning && _currentState.status == BleStatus.scanning) {
          _scanSubscription?.cancel();
          _scanSubscription = null;
          _emit(const BleState(
            status: BleStatus.error,
            errorMessage: 'No scale found. Tap to try again.',
          ));
        }
      });

      // Begin scanning
      // continuousUpdates: broadcast scales send the live weight in every
      // advertisement. Without it Android reports only the first advert per
      // device, so the reading would never update after stepping on.
      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        continuousUpdates: true,
      );
    } catch (e) {
      _emit(BleState(
        status: BleStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Stop scanning and disconnect any connected device.
  Future<void> stopScan() async {
    _isScanningSubscription?.cancel();
    _isScanningSubscription = null;
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    await _disconnect();
    _emit(const BleState(status: BleStatus.idle));
  }

  /// Release all resources.
  void dispose() {
    _isScanningSubscription?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _cancelCharSubscriptions();
    _connectedDevice?.disconnect();
    _stateController.close();
  }

  // ── Scan handling ──────────────────────────────────────────────────────

  void _onScanResults(List<ScanResult> results) {
    // With continuousUpdates the same device is reported repeatedly; ignore
    // results once a measurement completed or a connection is underway.
    if (_currentState.status != BleStatus.scanning &&
        _currentState.status != BleStatus.measuring) {
      return;
    }
    for (final result in results) {
      // 1) Try manufacturer data broadcast decoding (OKOK)
      final mfData = result.advertisementData.manufacturerData;
      for (final entry in mfData.entries) {
        final companyId = entry.key;
        final bytes = Uint8List.fromList(entry.value);
        final broadcast =
            BleBroadcastDecoder.decodeOkokBroadcast(
          companyId,
          bytes,
          deviceAddress: result.device.remoteId.str,
        );
        if (broadcast != null) {
          _handleBroadcast(broadcast, result.device);
          return;
        }
      }

      // 2) Check device name for GATT connection
      final name = result.advertisementData.advName;
      if (name.isNotEmpty && _matchesPrefix(name)) {
        _onDeviceFound(result.device, name);
        return;
      }
    }
  }

  bool _matchesPrefix(String name) {
    final lower = name.toLowerCase();
    return BleConstants.chipseaDeviceNamePrefixes
        .any((prefix) => lower.startsWith(prefix.toLowerCase()));
  }

  void _handleBroadcast(BroadcastResult broadcast, BluetoothDevice device) {
    final deviceName = device.advName.isNotEmpty ? device.advName : 'Unknown';

    _emit(BleState(
      status: broadcast.isFinalBia ? BleStatus.complete : BleStatus.measuring,
      weightKg: broadcast.weightKg,
      impedance:
          broadcast.impedance != null ? broadcast.impedance!.toInt() : null,
      isStable: broadcast.isStable,
      isFinalBia: broadcast.isFinalBia,
      deviceName: deviceName,
    ));
  }

  // ── GATT connection ────────────────────────────────────────────────────

  Future<void> _onDeviceFound(BluetoothDevice device, String name) async {
    _emit(BleState(status: BleStatus.found, deviceName: name));

    // Stop scanning before connecting (not a timeout, so drop the watcher)
    _isScanningSubscription?.cancel();
    _isScanningSubscription = null;
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      _connectedDevice = device;

      // Monitor connection state
      _connectionSubscription?.cancel();
      _connectionSubscription =
          device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('BleService: device disconnected');
          _cancelCharSubscriptions();
        }
      });

      await device.connect(timeout: const Duration(seconds: 10));
      await _discoverAndSubscribe(device);
    } catch (e) {
      debugPrint('BleService connect error: $e');
      _emit(BleState(
        status: BleStatus.error,
        deviceName: name,
        errorMessage: 'Connection failed: $e',
      ));
    }
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    final services = await device.discoverServices();
    _charSubscriptions = [];

    for (final service in services) {
      // ── V1 (FFF0) ────────────────────────────────────────────────────
      if (service.uuid == BleConstants.chipseaServiceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid == BleConstants.chipseaNotifyCharUuid) {
            await char.setNotifyValue(true);
            _charSubscriptions!.add(
              char.onValueReceived.listen((value) {
                final data = Uint8List.fromList(value);
                final result = BleProtocolDecoder.decodeChipseaV1(data);
                if (result != null) {
                  _emit(BleState(
                    status: BleStatus.complete,
                    weightKg: result.weightKg,
                    impedance: result.impedance,
                    isStable: true,
                    isFinalBia: result.impedance > 0,
                    deviceName: device.advName,
                  ));
                }
              }),
            );
          }
        }
      }

      // ── V2 (FFB0) ────────────────────────────────────────────────────
      if (service.uuid == BleConstants.chipseaV2ServiceUuid) {
        for (final char in service.characteristics) {
          // Weight characteristic
          if (char.uuid == BleConstants.chipseaV2WeightCharUuid) {
            await char.setNotifyValue(true);
            _charSubscriptions!.add(
              char.onValueReceived.listen((value) {
                final data = Uint8List.fromList(value);
                final result =
                    BleProtocolDecoder.decodeChipseaV2Weight(data);
                if (result != null) {
                  _emit(BleState(
                    status:
                        result.isStable ? BleStatus.stable : BleStatus.measuring,
                    weightKg: result.weightKg,
                    isStable: result.isStable,
                    deviceName: device.advName,
                  ));
                }
              }),
            );
          }

          // BIA characteristic
          if (char.uuid == BleConstants.chipseaV2BiaCharUuid) {
            await char.setNotifyValue(true);
            _charSubscriptions!.add(
              char.onValueReceived.listen((value) {
                final data = Uint8List.fromList(value);
                final result =
                    BleProtocolDecoder.decodeChipseaV2Bia(data);
                if (result != null) {
                  _emit(BleState(
                    status: BleStatus.complete,
                    weightKg: result.weightKg,
                    impedance: result.impedance,
                    isStable: true,
                    isFinalBia: true,
                    deviceName: device.advName,
                  ));
                }
              }),
            );
          }
        }
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _emit(BleState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  BleState get currentState => _currentState;

  void _cancelCharSubscriptions() {
    if (_charSubscriptions != null) {
      for (final sub in _charSubscriptions!) {
        sub.cancel();
      }
      _charSubscriptions = null;
    }
  }

  Future<void> _disconnect() async {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _cancelCharSubscriptions();
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
  }
}
