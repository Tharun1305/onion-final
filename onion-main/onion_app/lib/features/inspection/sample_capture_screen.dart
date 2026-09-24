import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/image_input.dart';
import '../../models/inspection.dart';
import '../ai_analysis/presentation/ai_analysis_screen.dart';
import '../camera/web_camera_view.dart';

class SampleCaptureScreen extends StatefulWidget {
  final Inspection inspection;

  const SampleCaptureScreen({super.key, required this.inspection});

  @override
  State<SampleCaptureScreen> createState() => _SampleCaptureScreenState();
}

class _SampleCaptureScreenState extends State<SampleCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
      _isCameraInitialized = false;
      _controller?.dispose();
      _controller = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      if (mounted) setState(() => _isCameraInitialized = false);
      cameraController.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No camera hardware found on this device.';
          });
        }
        return;
      }

      // Select rear camera by default, or the first available
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();
      debugPrint('[CAMERA] camera initialized');

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      debugPrint('[SampleCaptureScreen] CameraException: ${e.code}, ${e.description}');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          switch (e.code) {
            case 'CameraAccessDenied':
            case 'CameraAccessDeniedWithoutPrompt':
              _errorMessage = 'Camera permission was denied. Please grant camera access in app settings.';
              break;
            case 'CameraAccessRestricted':
              _errorMessage = 'Camera access is restricted on this device.';
              break;
            default:
              _errorMessage = 'Camera initialization failed: ${e.description ?? e.code}';
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('[SampleCaptureScreen] Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _errorMessage = 'Could not access device camera: $e';
        });
      }
    }
  }

  Future<void> _captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);

    try {
      final XFile photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      debugPrint('[CAMERA] capture completed');
      debugPrint('[IMAGE] filename: ${photo.name}');
      debugPrint('[IMAGE] mime type: image/jpeg');
      debugPrint('[IMAGE] bytes length: ${bytes.length}');
      await _onImageCaptured(photo.path, bytes, photo.name);
    } catch (e) {
      debugPrint('[SampleCaptureScreen] Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        debugPrint('[IMAGE] filename: ${picked.name}');
        debugPrint('[IMAGE] bytes length: ${bytes.length}');
        await _onImageCaptured(picked.path, bytes, picked.name);
      }
    } catch (e) {
      debugPrint('[SampleCaptureScreen] Gallery pick error: $e');
    }
  }

  Future<void> _onImageCaptured(String imagePath, Uint8List bytes, String filename) async {
    final updatedInspection = widget.inspection.copyWith(
      imagePaths: [imagePath],
      imageBytes: bytes,
      status: InspectionStatus.imagesReady,
      updatedAt: DateTime.now(),
    );

    final imageInput = ImageInput(
      bytes: bytes,
      filename: filename.isNotEmpty ? filename : 'onion_captured.jpg',
      localPath: kIsWeb ? null : imagePath,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AiAnalysisScreen(
          inspection: updatedInspection,
          imageInput: imageInput,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If Web (Chrome / Edge), use WebCameraView with browser getUserMedia
    if (kIsWeb) {
      return WebCameraView(
        inspection: widget.inspection,
        onCaptured: (imageInput) => _onImageCaptured(
          imageInput.filename,
          imageInput.bytes,
          imageInput.filename,
        ),
        onCancel: () => Navigator.of(context).pop(),
        onUploadPressed: _pickFromGallery,
      );
    }

    // Native Mobile (Android)
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capture Onion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            Text(
              'Batch: ${widget.inspection.batchId} • Step 2: Camera Sample',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center Viewfinder
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Camera Viewfinder
                  if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
                    Center(
                      child: CameraPreview(_controller!),
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
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry Camera'),
                                  onPressed: _initializeCamera,
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Upload Image'),
                                  onPressed: _pickFromGallery,
                                ),
                              ],
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
                            'Starting live camera...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                  // Rectangular Onion Scanning Area Overlay
                  if (_isCameraInitialized)
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

                  // Shutter processing overlay
                  if (_isTakingPicture)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppTheme.primaryTeal),
                            SizedBox(height: 12),
                            Text(
                              'Capturing sample...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Controls & Capture Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Gallery',
                    icon: const Icon(Icons.photo_library, color: Colors.white70, size: 28),
                    onPressed: _isTakingPicture ? null : _pickFromGallery,
                  ),
                  GestureDetector(
                    onTap: (_isCameraInitialized && !_isTakingPicture) ? _captureImage : null,
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
                            color: (_isCameraInitialized && !_isTakingPicture)
                                ? AppTheme.primaryTeal
                                : Colors.grey,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                  if (_cameras.length > 1)
                    IconButton(
                      tooltip: 'Flip Camera',
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white70, size: 28),
                      onPressed: () {
                        final currentLens = _controller?.description.lensDirection;
                        final nextCam = _cameras.firstWhere(
                          (c) => c.lensDirection != currentLens,
                          orElse: () => _cameras.first,
                        );
                        _controller?.dispose();
                        _controller = CameraController(
                          nextCam,
                          ResolutionPreset.high,
                          enableAudio: false,
                        );
                        _controller!.initialize().then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
