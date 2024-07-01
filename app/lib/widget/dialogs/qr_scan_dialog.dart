import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/provider/network/targeted_discovery_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class QRScanDialog extends StatefulWidget {
  const QRScanDialog();

  @override
  State<QRScanDialog> createState() => _QRScanDialogDialogState();
}

class _QRScanDialogDialogState extends State<QRScanDialog> with Refena {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  // bool _fetching = false;
  // bool _failed = false;

  Future<void> _checkConnectionToDevice(QRCodeDevice device) async {
    if (device.ip == null || device.port == null) {
      return;
    }

    // setState(() {
    //   _fetching = true;
    // });

    final https = ref.read(settingsProvider).https;

    final result = await ref.read(targetedDiscoveryProvider).discover(ip: device.ip!, port: device.port!, https: https);
    if (result == null) {
      // setState(() {
      //   _fetching = false;
      //   _failed = true;
      // });
      return;
    }

    if (!mounted) {
      return;
    }
    try {
      context.pop(result);
    } catch (e) {}
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: double.infinity,
        child: Scaffold(
          body: Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(child: Builder(
                  builder: (BuildContext context) {
                    if (result != null) {
                      check();
                      return Text('Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}');
                    } else {
                      return const Text('Scan a code');
                    }
                  },
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  void check() async {
    // if (!_fetching) {
      await _checkConnectionToDevice(QRCodeDevice.fromResult(result));
    // }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class QRCodeDevice {
  String? ip;
  int? port;

  QRCodeDevice({
    required this.ip,
    required this.port,
  });

  QRCodeDevice.fromResult(Barcode? result) {
    var split = result?.code?.split(':');
    ip = split?.first;
    port = int.parse(split?.last ?? '53317');
  }
}
