// ignore_avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/image_input.dart';
import '../../models/inspection.dart';

class WebCameraView extends StatefulWidget {
  final Inspection inspection;
  final Function(ImageInput imageInput) onCaptured;
  final VoidCallback onCancel;
  final VoidCallback onUploadPressed;

  const WebCameraView({
    super.key,
    required this.inspection,
    required this.onCaptured,
    required this.onCancel,
    required this.onUploadPressed,
  });

  @override
  State<WebCameraView> createState() => _WebCameraViewState();
}

class _WebCameraViewState extends State<WebCameraView> {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';
    _initializeWebcam();
  }

  Future<void> _initializeWebcam() async {
    setState(() {
      _errorMessage = null;
    });

    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _errorMessage = 'Camera hardware is not accessible in this browser.';
        });
      }
      return;
    }

    try {
      // Request camera stream from browser (Chrome / Edge)
      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _mediaStream = stream;

      final video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..srcObject = stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.border = 'none';

      _videoElement = video;

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => video,
      );

      debugPrint('[CAMERA] camera initialized');

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[CAMERA] webcam permission/initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _errorMessage = 'Camera permission is required to use your webcam.';
        });
      }
    }
  }

  Future<void> _captureFrame() async {
    final video = _videoElement;
    if (video == null || _isCapturing || !_isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      final width = video.videoWidth > 0 ? video.videoWidth : 1280;
      final height = video.videoHeight > 0 ? video.videoHeight : 720;

      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImage(video, 0, 0);

      // High-quality JPEG snapshot
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.95);
      final base64String = dataUrl.split(',').last;
      final bytes = base64Decode(base64String);

      debugPrint('[CAMERA] capture completed');
      debugPrint('[IMAGE] filename: laptop_webcam_sample.jpg');
      debugPrint('[IMAGE] mime type: image/jpeg');
      debugPrint('[IMAGE] bytes length: ${bytes.length}');

      final imageInput = ImageInput(
        bytes: bytes,
        filename: 'laptop_webcam_sample.jpg',
        mimeType: 'image/jpeg',
      );

      widget.onCaptured(imageInput);
    } catch (e) {
      debugPrint('[CAMERA] error capturing frame: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture frame: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    try {
      _mediaStream?.getTracks().forEach((track) {
        track.stop();
      });
      _videoElement?.srcObject = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onCancel,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capture Onion (Webcam)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Batch: ${widget.inspection.batchId} • Browser Camera',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Viewfinder Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Live Video Stream
                  if (_isInitialized)
                    Center(
                      child: HtmlElementView(viewType: _viewType),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_off, color: Color(0xFFEF4444), size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please enable camera permissions in your browser address bar and retry.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  onPressed: widget.onCancel,
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  onPressed: _initializeWebcam,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.photo_library, color: Color(0xFF38BDF8), size: 18),
                              label: const Text('Or Upload Image from Laptop', style: TextStyle(color: Color(0xFF38BDF8))),
                              onPressed: widget.onUploadPressed,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryTeal),
                          SizedBox(height: 16),
                          Text(
                            'Requesting laptop webcam permission...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  // Scanning Frame Overlay
                  if (_isInitialized)
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          margin: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryTeal, width: 2.5),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.white, width: 3.5),
                                      left: BorderSide(color: Colors.white, width: 3.5),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.white, width: 3.5),
                                      right: BorderSide(color: Colors.white, width: 3.5),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.white, width: 3.5),
                                      left: BorderSide(color: Colors.white, width: 3.5),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.white, width: 3.5),
                                      right: BorderSide(color: Colors.white, width: 3.5),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Place one onion inside the frame',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Shutter Overlay
                  if (_isCapturing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primaryTeal),
                            SizedBox(height: 12),
                            Text(
                              'Capturing webcam frame...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Upload Image option
                  IconButton(
                    tooltip: 'Upload Image from Laptop',
                    icon: const Icon(Icons.photo_library, color: Colors.white70, size: 28),
                    onPressed: _isCapturing ? null : widget.onUploadPressed,
                  ),

                  // Circular Shutter [Capture] Button
                  GestureDetector(
                    onTap: (_isInitialized && !_isCapturing) ? _captureFrame : null,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isInitialized && !_isCapturing)
                                ? AppTheme.primaryTeal
                                : Colors.grey,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),

                  // Refresh / Re-init camera
                  IconButton(
                    tooltip: 'Refresh Webcam',
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 28),
                    onPressed: _isCapturing ? null : _initializeWebcam,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
