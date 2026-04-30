// lib/screens/camera/camera_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

/// NOTE: Real camera + OCR uses the `camera` and
/// `google_mlkit_text_recognition` packages on Android/iOS.
/// On web (Chrome/Edge) those plugins are unavailable â€” we show a
/// clear fallback UI instead of crashing.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _flashOn    = false;
  String? _extracted;
  final TextEditingController _editController = TextEditingController();

  late final AnimationController _scanLineCtrl;
  late final Animation<double>   _scanLine;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _editController.dispose();
    super.dispose();
  }

  // â”€â”€ Stub capture (replace with real MLKit call on mobile) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _capture() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _extracted =
          'Pakistan stocks closed higher on Wednesday, with the benchmark '
          'KSE-100 index gaining 412 points to settle at 93,214 â€” driven '
          'by buying in cement and banking sectors. Analysts cite improving '
          'macroeconomic signals and IMF tranche expectations as key drivers.';
      _editController.text = _extracted!;
    });
  }

  Future<void> _galleryPick() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _extracted =
          'Sample text extracted from gallery image. '
          'Edit this before sending to the AI for summarisation.';
      _editController.text = _extracted!;
    });
  }

  void _sendToAI() {
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  void _retake() => setState(() {
        _extracted = null;
        _editController.clear();
      });

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    // âœ… Web guard â€” camera doesn't work in browser
    if (kIsWeb) return _buildWebFallback();

    if (_extracted != null) return _buildConfirmView();
    return _buildScanView();
  }

  // â”€â”€ Web fallback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildWebFallback() {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.amberAccent.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color:
                      AppColors.amberAccent.withOpacity(0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.amberAccent, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Camera is only available on Android/iOS.\n'
                      'On web, paste your text directly below.',
                      style: TextStyle(
                        color: AppColors.amberAccent,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Paste or type article text',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLg),
                  border:
                      Border.all(color: AppColors.dividerColor),
                ),
                child: TextField(
                  controller: _editController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText:
                        'Paste a newspaper article, report, or any text hereâ€¦',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                if (_editController.text.trim().isNotEmpty) {
                  _extracted = _editController.text.trim();
                  _sendToAI();
                }
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Summarise with AI'),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Mobile scan view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildScanView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A0A0A), Color(0xFF1C1C1C)],
                ),
              ),
            ),
          ),

          // Overlay with cutout + scan line
          Positioned.fill(
            child: _ScanOverlay(
              scanLineAnim: _scanLine,
              isScanning: _isScanning,
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    'Scan Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _flashOn ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => _flashOn = !_flashOn),
                  ),
                ],
              ),
            ),
          ),

          // Hint text
          const Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Text(
              'Position the text inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(32, 24, 32, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CircleBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: _galleryPick,
                  ),

                  // Shutter
                  GestureDetector(
                    onTap: _isScanning ? null : _capture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isScanning
                            ? Colors.white38
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: _isScanning
                          ? const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded,
                              color: Colors.black, size: 30),
                    ),
                  ),

                  const SizedBox(width: 50), // balance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Confirm / edit view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildConfirmView() {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Confirm Text'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _retake,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.greenPositive
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: AppColors.greenPositive
                      .withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.greenPositive,
                      size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Text extracted! Review and edit before sending.',
                      style: TextStyle(
                        color: AppColors.greenPositive,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Extracted Text',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(
                      color: AppColors.dividerColor),
                ),
                child: TextField(
                  controller: _editController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Edit extracted textâ€¦',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retake,
                    icon: const Icon(Icons.camera_alt_rounded,
                        size: 16),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          AppColors.textSecondary,
                      side: const BorderSide(
                          color: AppColors.dividerColor),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _sendToAI,
                    icon: const Icon(Icons.auto_awesome_rounded,
                        size: 16),
                    label: const Text('Summarise with AI'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Scan overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ScanOverlay extends StatelessWidget {
  final Animation<double> scanLineAnim;
  final bool isScanning;
  const _ScanOverlay(
      {required this.scanLineAnim, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxW = size.width * 0.80;
    const boxH = 200.0;
    final boxX = (size.width - boxW) / 2;
    final boxY = size.height * 0.28;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(
              rect: Rect.fromLTWH(boxX, boxY, boxW, boxH)),
        ),
        Positioned(
          left: boxX,
          top: boxY,
          child: _CornerBrackets(w: boxW, h: boxH),
        ),
        if (isScanning)
          AnimatedBuilder(
            animation: scanLineAnim,
            builder: (_, __) => Positioned(
              left: boxX,
              top: boxY + scanLineAnim.value * (boxH - 2),
              child: Container(
                width: boxW,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue
                          .withOpacity(0),
                      AppColors.primaryBlue,
                      AppColors.primaryBlue
                          .withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect rect;
  const _OverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.rect != rect;
}

class _CornerBrackets extends StatelessWidget {
  final double w, h;
  const _CornerBrackets({required this.w, required this.h});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: w, height: h, child: CustomPaint(painter: _BracketPainter()));
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 22.0;
    const r   = 12.0;
    final paint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final corners = [
      [const Offset(r, 0), const Offset(r + len, 0), const Offset(0, r), const Offset(0, r + len)],
      [Offset(size.width - r, 0), Offset(size.width - r - len, 0),
       Offset(size.width, r), Offset(size.width, r + len)],
      [Offset(r, size.height), Offset(r + len, size.height),
       Offset(0, size.height - r), Offset(0, size.height - r - len)],
      [Offset(size.width - r, size.height),
       Offset(size.width - r - len, size.height),
       Offset(size.width, size.height - r),
       Offset(size.width, size.height - r - len)],
    ];
    for (final c in corners) {
      canvas.drawLine(c[0], c[1], paint);
      canvas.drawLine(c[2], c[3], paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}