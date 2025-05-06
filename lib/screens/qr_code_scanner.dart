import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture barcode) {
              if (!isScanning) return;

              if (barcode.barcodes.isNotEmpty) {
                final String? code = barcode.barcodes.first.rawValue;
                if (code != null) {
                  setState(() => isScanning = false);
                  controller
                      .stop(); // Stop the scanner after detecting a valid QR code
                  HapticFeedback.mediumImpact();

                  // Show success animation
                  _showSuccessDialog(code);
                } else {
                  _showErrorOverlay('Unable to read QR code');
                }
              }
            },
          ),

          // Scanning overlay
          Container(
            decoration: ShapeDecoration(
              shape: ScannerOverlayShape(
                borderColor: Colors.white,
                borderWidth: 3.0,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
                borderRadius: 12,
                overlayColor: Colors.black54,
              ),
            ),
          ),

          // Scanning line animation
          if (isScanning)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(
                      top:
                          100 +
                          (MediaQuery.of(context).size.width * 0.7 - 30) *
                              _animation.value,
                      left: MediaQuery.of(context).size.width * 0.15,
                      right: MediaQuery.of(context).size.width * 0.15,
                    ),
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0),
                          Colors.blue,
                          Colors.blue.withOpacity(0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Instructions text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: const Text(
                'Position the QR code within the frame to scan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // Controls row
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => isScanning = true);
                      controller
                          .start(); // Restart the scanner when the button is pressed
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () => controller.switchCamera(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorOverlay(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 150, left: 20, right: 20),
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String code) {
    Navigator.pop(
      context,
      code,
    ); // Return the scanned QR code to the previous screen
  }
}

// Scanner overlay shape class
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double cutOutSize;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.overlayColor = Colors.black54,
    this.borderRadius = 10,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getOuterPath(Rect rect) {
      final cutOutRect = Rect.fromCenter(
        center: rect.center,
        width: cutOutSize,
        height: cutOutSize,
      );
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(rect)
        ..addRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        );
    }

    return _getOuterPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final boxPaint =
        Paint()
          ..color = overlayColor
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.srcOut;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final boxPath =
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(rect)
          ..addRRect(
            RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
          );

    canvas.drawPath(boxPath, boxPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
