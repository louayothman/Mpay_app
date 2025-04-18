import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // الحد الأقصى لحجم الملف (10 ميجابايت)
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // الحد الأقصى لأبعاد الصورة
  static const int _maxImageDimension = 2048;
  
  // أنواع الملفات المسموح بها
  static const List<String> _allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'text/plain',
  ];
  
  // التحقق من حجم الملف
  Future<bool> _validateFileSize(File file) async {
    final size = await file.length();
    return size <= _maxFileSize;
  }
  
  // التحقق من حجم البيانات
  bool _validateDataSize(Uint8List data) {
    return data.length <= _maxFileSize;
  }
  
  // التحقق من نوع الملف
  bool _validateFileType(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType != null && _allowedMimeTypes.contains(mimeType);
  }
  
  // التحقق من نوع البيانات
  bool _validateDataType(Uint8List data, String? mimeType) {
    if (mimeType == null) {
      // محاولة تحديد نوع الملف من البيانات
      final header = data.length > 12 ? data.sublist(0, 12) : data;
      final detectedType = _detectMimeType(header);
      return detectedType != null && _allowedMimeTypes.contains(detectedType);
    }
    return _allowedMimeTypes.contains(mimeType);
  }
  
  // تحديد نوع الملف من البيانات
  String? _detectMimeType(Uint8List header) {
    if (header.length >= 2) {
      // JPEG signature
      if (header[0] == 0xFF && header[1] == 0xD8) {
        return 'image/jpeg';
      }
      
      // PNG signature
      if (header.length >= 8 &&
          header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && 
          header[3] == 0x47 && header[4] == 0x0D && header[5] == 0x0A && 
          header[6] == 0x1A && header[7] == 0x0A) {
        return 'image/png';
      }
      
      // PDF signature
      if (header.length >= 4 &&
          header[0] == 0x25 && header[1] == 0x50 && header[2] == 0x44 && header[3] == 0x46) {
        return 'application/pdf';
      }
    }
    
    return null;
  }
  
  // ضغط الصورة إذا كانت كبيرة جدًا
  Future<File> _compressImageIfNeeded(File file) async {
    try {
      // التحقق من نوع الملف
      final extension = path.extension(file.path).toLowerCase();
      if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
        return file; // ليست صورة، إرجاع الملف كما هو
      }
      
      // قراءة الصورة
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return file; // فشل في قراءة الصورة، إرجاع الملف كما هو
      }
      
      // التحقق مما إذا كانت الصورة كبيرة جدًا
      if (image.width <= _maxImageDimension && image.height <= _maxImageDimension && bytes.length <= _maxFileSize) {
        return file; // الصورة ضمن الحدود المسموح بها
      }
      
      // حساب الأبعاد الجديدة مع الحفاظ على نسبة العرض إلى الارتفاع
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > _maxImageDimension || image.height > _maxImageDimension) {
        if (image.width > image.height) {
          newWidth = _maxImageDimension;
          newHeight = (image.height * _maxImageDimension / image.width).round();
        } else {
          newHeight = _maxImageDimension;
          newWidth = (image.width * _maxImageDimension / image.height).round();
        }
      }
      
      // تغيير حجم الصورة
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
      
      // ضغط الصورة
      Uint8List compressedBytes;
      int quality = 85; // جودة الضغط الأولية
      
      if (extension == '.png') {
        compressedBytes = Uint8List.fromList(img.encodePng(resizedImage));
      } else {
        // JPEG أو WebP
        compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        
        // إذا كان الحجم لا يزال كبيرًا، قم بضغط أكثر
        while (compressedBytes.length > _maxFileSize && quality > 40) {
          quality -= 10;
          compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
        }
      }
      
      // إنشاء ملف مؤقت جديد للصورة المضغوطة
      final tempDir = await Directory.systemTemp.createTemp('compressed_images');
      final compressedFile = File('${tempDir.path}/compressed_${path.basename(file.path)}');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file; // في حالة حدوث خطأ، إرجاع الملف الأصلي
    }
  }
  
  // رفع ملف مع التحقق من الحجم والنوع
  Future<String?> uploadFile({
    required BuildContext context,
    required File file,
    required String path,
    bool showLoading = true,
    bool compressImages = true,
    int? maxSizeBytes,
    List<String>? allowedTypes,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        // التحقق من نوع الملف
        final isValidType = allowedTypes != null 
            ? allowedTypes.contains(lookupMimeType(file.path))
            : _validateFileType(file);
            
        if (!isValidType) {
          throw Exception('نوع الملف غير مسموح به');
        }
        
        // التحقق من حجم الملف
        final effectiveMaxSize = maxSizeBytes ?? _maxFileSize;
        final fileSize = await file.length();
        
        if (fileSize > effectiveMaxSize) {
          if (compressImages && (lookupMimeType(file.path)?.startsWith('image/') ?? false)) {
            // محاولة ضغط الصورة
            file = await _compressImageIfNeeded(file);
            
            // التحقق مرة أخرى بعد الضغط
            final compressedSize = await file.length();
            if (compressedSize > effectiveMaxSize) {
              throw Exception('حجم الملف كبير جدًا (${(compressedSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت). الحد الأقصى هو ${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت.');
            }
          } else {
            throw Exception('حجم الملف كبير جدًا (${(fileSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت). الحد الأقصى هو ${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت.');
          }
        }
        
        // إنشاء البيانات الوصفية
        final metadata = SettableMetadata(
          contentType: lookupMimeType(file.path),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalSize': fileSize.toString(),
          },
        );
        
        // رفع الملف مع إظهار تقدم الرفع
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(file, metadata);
        
        // مراقبة تقدم الرفع
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });
        
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      },
      loadingMessage: 'جاري رفع الملف...',
      successMessage: 'تم رفع الملف بنجاح',
      errorMessage: 'فشل في رفع الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // رفع بيانات مع التحقق من الحجم والنوع
  Future<String?> uploadData({
    required BuildContext context,
    required Uint8List data,
    required String path,
    String? mimeType,
    bool showLoading = true,
    int? maxSizeBytes,
    List<String>? allowedTypes,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        // التحقق من نوع البيانات
        final isValidType = allowedTypes != null 
            ? allowedTypes.contains(mimeType)
            : _validateDataType(data, mimeType);
            
        if (!isValidType) {
          throw Exception('نوع الملف غير مسموح به');
        }
        
        // التحقق من حجم البيانات
        final effectiveMaxSize = maxSizeBytes ?? _maxFileSize;
        
        if (data.length > effectiveMaxSize) {
          throw Exception('حجم البيانات كبير جدًا (${(data.length / 1024 / 1024).toStringAsFixed(2)} ميجابايت). الحد الأقصى هو ${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت.');
        }
        
        // إنشاء البيانات الوصفية
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'size': data.length.toString(),
          },
        );
        
        // رفع البيانات مع إظهار تقدم الرفع
        final ref = _storage.ref().child(path);
        final uploadTask = ref.putData(data, metadata);
        
        // مراقبة تقدم الرفع
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });
        
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      },
      loadingMessage: 'جاري رفع البيانات...',
      successMessage: 'تم رفع البيانات بنجاح',
      errorMessage: 'فشل في رفع البيانات',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // تنزيل ملف مع التحقق من الحجم
  Future<Uint8List?> downloadFile({
    required BuildContext context,
    required String path,
    bool showLoading = true,
    int? maxSizeBytes,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        // الحصول على البيانات الوصفية للملف أولاً للتحقق من الحجم
        final ref = _storage.ref().child(path);
        final metadata = await ref.getMetadata();
        
        // التحقق من حجم الملف
        final effectiveMaxSize = maxSizeBytes ?? _maxFileSize;
        if (metadata.size != null && metadata.size! > effectiveMaxSize) {
          throw Exception('حجم الملف كبير جدًا (${(metadata.size! / 1024 / 1024).toStringAsFixed(2)} ميجابايت). الحد الأقصى هو ${(effectiveMaxSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت.');
        }
        
        // تنزيل الملف
        return await ref.getData();
      },
      loadingMessage: 'جاري تنزيل الملف...',
      successMessage: 'تم تنزيل الملف بنجاح',
      errorMessage: 'فشل في تنزيل الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // لا تظهر رسالة نجاح للتنزيلات
    );
  }
  
  // الحصول على رابط التنزيل
  Future<String?> getDownloadURL({
    required BuildContext context,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        final ref = _storage.ref().child(path);
        return await ref.getDownloadURL();
      },
      loadingMessage: 'جاري الحصول على رابط التنزيل...',
      successMessage: 'تم الحصول على رابط التنزيل بنجاح',
      errorMessage: 'فشل في الحصول على رابط التنزيل',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // لا تظهر رسالة نجاح للحصول على الروابط
    );
  }
  
  // حذف ملف
  Future<void> deleteFile({
    required BuildContext context,
    required String path,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        final ref = _storage.ref().child(path);
        return await ref.delete();
      },
      loadingMessage: 'جاري حذف الملف...',
      successMessage: 'تم حذف الملف بنجاح',
      errorMessage: 'فشل في حذف الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: true,
    );
  }
  
  // رفع صورة الملف الشخصي مع التحقق والضغط
  Future<String?> uploadProfilePicture({
    required BuildContext context,
    required File file,
    required String userId,
    bool showLoading = true,
  }) async {
    // التحقق من أن الملف هو صورة
    final mimeType = lookupMimeType(file.path);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      ErrorHandler.showErrorSnackBar(context, 'يجب أن يكون الملف صورة');
      return null;
    }
    
    final path = 'profile_pictures/$userId.jpg';
    return await uploadFile(
      context: context,
      file: file,
      path: path,
      showLoading: showLoading,
      compressImages: true,
      maxSizeBytes: 2 * 1024 * 1024, // 2MB كحد أقصى لصور الملف الشخصي
      allowedTypes: ['image/jpeg', 'image/png', 'image/webp'],
    );
  }
  
  // رفع إيصال المعاملة مع التحقق والضغط
  Future<String?> uploadTransactionReceipt({
    required BuildContext context,
    required File file,
    required String transactionId,
    bool showLoading = true,
  }) async {
    // التحقق من أن الملف هو صورة أو PDF
    final mimeType = lookupMimeType(file.path);
    if (mimeType == null || (!mimeType.startsWith('image/') && mimeType != 'application/pdf')) {
      ErrorHandler.showErrorSnackBar(context, 'يجب أن يكون الملف صورة أو PDF');
      return null;
    }
    
    final extension = mimeType == 'application/pdf' ? '.pdf' : '.jpg';
    final path = 'transaction_receipts/$transactionId$extension';
    
    return await uploadFile(
      context: context,
      file: file,
      path: path,
      showLoading: showLoading,
      compressImages: mimeType.startsWith('image/'),
      maxSizeBytes: 5 * 1024 * 1024, // 5MB كحد أقصى لإيصالات المعاملات
      allowedTypes: ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
    );
  }
  
  // تنزيل ملف من URL
  Future<File?> downloadFileFromUrl({
    required BuildContext context,
    required String url,
    required String localPath,
    bool showLoading = true,
  }) async {
    return await ErrorHandler.handleNetworkOperation(
      context: context,
      operation: () async {
        // التحقق من الاتصال بالإنترنت
        final isConnected = await ConnectivityUtils.isConnected();
        if (!isConnected) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }
        
        // تنزيل الملف
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode != 200) {
          throw Exception('فشل في تنزيل الملف: ${response.statusCode}');
        }
        
        // التحقق من حجم الملف
        if (response.bodyBytes.length > _maxFileSize) {
          throw Exception('حجم الملف كبير جدًا (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(2)} ميجابايت). الحد الأقصى هو ${(_maxFileSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت.');
        }
        
        // حفظ الملف محليًا
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        
        return file;
      },
      loadingMessage: 'جاري تنزيل الملف...',
      successMessage: 'تم تنزيل الملف بنجاح',
      errorMessage: 'فشل في تنزيل الملف',
      showLoadingDialog: showLoading,
      showSuccessMessage: false, // لا تظهر رسالة نجاح للتنزيلات
    );
  }
}
