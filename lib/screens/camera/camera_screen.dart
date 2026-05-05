// lib/screens/camera/camera_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../services/ocr_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isScanning = false;
  bool _flashOn = false;
  String? _extracted;
  String? _errorMessage;
  final TextEditingController _editController = TextEditingController();

  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() => _errorMessage = 'Camera not supported on web');
      return;
    }

    try {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        setState(() => _errorMessage = 'Camera permission denied');
        return;
      }
      if (status.isPermanentlyDenied) {
        setState(() => _errorMessage = 'Camera permission permanently denied. Please enable in settings.');
        return;
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _errorMessage = 'No cameras found on device');
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high, // Changed from max to high for better compatibility
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      setState(() => _isReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _scanLineCtrl.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isScanning) return;

    setState(() => _isScanning = true);
    try {
      final image = await _controller!.takePicture();
      final text = await OcrService.instance.extractTextFromImage(image.path);
      
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _extracted = text ?? '';
        _editController.text = _extracted!;
      });
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  void _sendToAI() {
    final text = _editController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text to summarize')),
      );
      return;
    }
    Navigator.pop(context, text);
  }

  void _retake() => setState(() {
        _extracted = null;
        _editController.clear();
      });

  @override
  Widget build(BuildContext context) {
    if (_extracted != null) return _buildConfirmView();
    return _buildScanView();
  }

  Widget _buildScanView() {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. Camera Preview (Background)
            if (_isReady && _controller != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: size.width,
                    height: size.width / _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorUI()
            else
              const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),

            // 2. Scan Overlay
            if (_isReady && _errorMessage == null)
              Positioned.fill(
                child: _ScanOverlay(
                  scanLineAnim: _scanLine,
                  isScanning: _isScanning,
                ),
              ),

            // 3. Top bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _IconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Text(
                        'SCAN DOCUMENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      if (_isReady)
                        _IconButton(
                          icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _flashOn ? AppColors.amberAccent : Colors.white,
                          onTap: () async {
                            setState(() => _flashOn = !_flashOn);
                            await _controller?.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
                          },
                        )
                      else
                        const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Bottom Controls
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(context).padding.bottom + 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.5), Colors.black],
                  ),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: (_isReady && !_isScanning) ? _capture : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (_isReady && !_isScanning) ? Colors.white : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: _isScanning
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                            : const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.redNegative, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown camera error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initCamera,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmView() {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Confirm Text'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _retake,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: TextField(
                  controller: _editController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'No text detected. Type or paste here...',
                    hintStyle: TextStyle(color: AppColors.textHint),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _retake,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.dividerColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('RETAKE'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _sendToAI,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('SUMMARISE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _IconButton({required this.icon, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final Animation<double> scanLineAnim;
  final bool isScanning;
  const _ScanOverlay({required this.scanLineAnim, required this.isScanning});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxW = size.width * 0.8;
    final boxH = size.height * 0.5;
    final boxX = (size.width - boxW) / 2;
    final boxY = (size.height - boxH) / 2 - 40;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _OverlayPainter(rect: Rect.fromLTWH(boxX, boxY, boxW, boxH)),
        ),
        _ScannerCorners(rect: Rect.fromLTWH(boxX, boxY, boxW, boxH)),
        AnimatedBuilder(
          animation: scanLineAnim,
          builder: (_, __) => Positioned(
            left: boxX + 10,
            top: boxY + scanLineAnim.value * boxH,
            child: Container(
              width: boxW - 20,
              height: 3,
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.8), blurRadius: 15, spreadRadius: 2)],
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.primaryBlue, AppColors.primaryBlue, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        if (isScanning)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryBlue),
                    SizedBox(height: 16),
                    Text('Analyzing...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScannerCorners extends StatelessWidget {
  final Rect rect;
  const _ScannerCorners({required this.rect});

  @override
  Widget build(BuildContext context) {
    const double len = 30;
    const double thick = 4;
    const Color col = AppColors.primaryBlue;

    return Stack(
      children: [
        Positioned(left: rect.left, top: rect.top, child: _Corner(len: len, thick: thick, col: col, isTop: true, isLeft: true)),
        Positioned(left: rect.right - len, top: rect.top, child: _Corner(len: len, thick: thick, col: col, isTop: true, isLeft: false)),
        Positioned(left: rect.left, top: rect.bottom - len, child: _Corner(len: len, thick: thick, col: col, isTop: false, isLeft: true)),
        Positioned(left: rect.right - len, top: rect.bottom - len, child: _Corner(len: len, thick: thick, col: col, isTop: false, isLeft: false)),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final double len;
  final double thick;
  final Color col;
  final bool isTop;
  final bool isLeft;
  const _Corner({required this.len, required this.thick, required this.col, required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: len, height: len,
      child: Stack(
        children: [
          Positioned(
            left: isLeft ? 0 : null, right: isLeft ? null : 0,
            top: isTop ? 0 : null, bottom: isTop ? null : 0,
            child: Container(width: len, height: thick, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(thick))),
          ),
          Positioned(
            left: isLeft ? 0 : null, right: isLeft ? null : 0,
            top: isTop ? 0 : null, bottom: isTop ? null : 0,
            child: Container(width: thick, height: len, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(thick))),
          ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect rect;
  const _OverlayPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), borderPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.rect != rect;
}