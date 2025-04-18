/**
 * @file documentation_generator.dart
 * @brief مولد التوثيق التلقائي للمشروع
 * 
 * يوفر هذا الملف أدوات لتوليد توثيق شامل للمشروع بشكل تلقائي
 * ويتضمن وظائف لتحليل الكود وتوليد تعليقات توثيقية وإنشاء ملفات توثيق
 * 
 * @author فريق MPay
 * @version 1.0.0
 * @date أبريل 2025
 */

import 'dart:io';
import 'package:path/path.dart' as path;

/// مولد التوثيق
/// 
/// يوفر هذا الصف أدوات لتوليد توثيق شامل للمشروع بشكل تلقائي
/// ويتضمن وظائف لتحليل الكود وتوليد تعليقات توثيقية وإنشاء ملفات توثيق
class DocumentationGenerator {
  /// مسار مجلد المشروع
  final String projectPath;
  
  /// مسار مجلد التوثيق
  final String docsPath;
  
  /// قائمة بامتدادات الملفات التي سيتم توثيقها
  final List<String> fileExtensions;
  
  /// قائمة بالمجلدات التي سيتم تجاهلها
  final List<String> ignoredFolders;
  
  /// قائمة بالملفات التي سيتم تجاهلها
  final List<String> ignoredFiles;
  
  /// إنشاء مثيل جديد من مولد التوثيق
  /// 
  /// @param projectPath مسار مجلد المشروع
  /// @param docsPath مسار مجلد التوثيق
  /// @param fileExtensions قائمة بامتدادات الملفات التي سيتم توثيقها
  /// @param ignoredFolders قائمة بالمجلدات التي سيتم تجاهلها
  /// @param ignoredFiles قائمة بالملفات التي سيتم تجاهلها
  DocumentationGenerator({
    required this.projectPath,
    required this.docsPath,
    this.fileExtensions = const ['.dart'],
    this.ignoredFolders = const ['.git', '.dart_tool', 'build', '.idea', '.vscode'],
    this.ignoredFiles = const ['.DS_Store', 'pubspec.lock'],
  });
  
  /// توليد توثيق للمشروع
  /// 
  /// يقوم بتحليل ملفات المشروع وتوليد توثيق شامل لها
  /// 
  /// @return عدد الملفات التي تم توثيقها
  Future<int> generateDocumentation() async {
    // إنشاء مجلد التوثيق إذا لم يكن موجودًا
    final docsDir = Directory(docsPath);
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    
    // إنشاء ملف فهرس التوثيق
    final indexFile = File(path.join(docsPath, 'index.md'));
    await indexFile.writeAsString('# توثيق مشروع MPay\n\n');
    
    // تحليل ملفات المشروع
    final projectDir = Directory(projectPath);
    final files = await _getProjectFiles(projectDir);
    
    // توليد توثيق لكل ملف
    int documentedFilesCount = 0;
    for (final file in files) {
      final relativePath = path.relative(file.path, from: projectPath);
      
      // تجاهل الملفات المستثناة
      if (_shouldIgnoreFile(file.path)) {
        continue;
      }
      
      // توليد توثيق للملف
      final wasDocumented = await _generateFileDocumentation(file, relativePath);
      if (wasDocumented) {
        documentedFilesCount++;
        
        // إضافة الملف إلى فهرس التوثيق
        await indexFile.writeAsString(
          '- [${path.basename(file.path)}](${_getDocumentationPath(relativePath)})\n',
          mode: FileMode.append,
        );
      }
    }
    
    // توليد ملف README.md
    await _generateReadme();
    
    // توليد ملف هيكل المشروع
    await _generateProjectStructure();
    
    return documentedFilesCount;
  }
  
  /// الحصول على قائمة بملفات المشروع
  /// 
  /// @param dir مجلد المشروع
  /// @return قائمة بملفات المشروع
  Future<List<File>> _getProjectFiles(Directory dir) async {
    final files = <File>[];
    
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final extension = path.extension(entity.path);
        if (fileExtensions.contains(extension)) {
          files.add(entity);
        }
      }
    }
    
    return files;
  }
  
  /// التحقق مما إذا كان يجب تجاهل الملف
  /// 
  /// @param filePath مسار الملف
  /// @return true إذا كان يجب تجاهل الملف، false خلاف ذلك
  bool _shouldIgnoreFile(String filePath) {
    final fileName = path.basename(filePath);
    if (ignoredFiles.contains(fileName)) {
      return true;
    }
    
    for (final folder in ignoredFolders) {
      if (filePath.contains('/$folder/') || filePath.contains('\\$folder\\')) {
        return true;
      }
    }
    
    return false;
  }
  
  /// توليد توثيق لملف
  /// 
  /// @param file ملف المصدر
  /// @param relativePath المسار النسبي للملف
  /// @return true إذا تم توليد التوثيق بنجاح، false خلاف ذلك
  Future<bool> _generateFileDocumentation(File file, String relativePath) async {
    try {
      // قراءة محتوى الملف
      final content = await file.readAsString();
      
      // تحليل الملف
      final fileInfo = _analyzeFile(content, path.basename(file.path));
      
      // إنشاء ملف التوثيق
      final docPath = path.join(docsPath, _getDocumentationPath(relativePath));
      final docDir = Directory(path.dirname(docPath));
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      
      final docFile = File(docPath);
      await docFile.writeAsString(fileInfo.documentation);
      
      return true;
    } catch (e) {
      print('خطأ في توليد توثيق للملف $relativePath: $e');
      return false;
    }
  }
  
  /// الحصول على مسار ملف التوثيق
  /// 
  /// @param relativePath المسار النسبي للملف
  /// @return مسار ملف التوثيق
  String _getDocumentationPath(String relativePath) {
    final extension = path.extension(relativePath);
    final baseName = path.basenameWithoutExtension(relativePath);
    final dirName = path.dirname(relativePath);
    
    return path.join(dirName, '$baseName.md');
  }
  
  /// تحليل ملف
  /// 
  /// @param content محتوى الملف
  /// @param fileName اسم الملف
  /// @return معلومات الملف
  FileInfo _analyzeFile(String content, String fileName) {
    // تحليل الكلاسات والدوال
    final classes = _extractClasses(content);
    final functions = _extractFunctions(content);
    
    // توليد توثيق للملف
    final documentation = _generateFileMarkdown(fileName, content, classes, functions);
    
    return FileInfo(
      fileName: fileName,
      classes: classes,
      functions: functions,
      documentation: documentation,
    );
  }
  
  /// استخراج الكلاسات من محتوى الملف
  /// 
  /// @param content محتوى الملف
  /// @return قائمة بالكلاسات
  List<ClassInfo> _extractClasses(String content) {
    final classes = <ClassInfo>[];
    final classRegex = RegExp(r'class\s+(\w+)(?:\s+extends\s+(\w+))?(?:\s+implements\s+([\w\s,]+))?');
    final matches = classRegex.allMatches(content);
    
    for (final match in matches) {
      final className = match.group(1) ?? '';
      final extendsClass = match.group(2);
      final implementsClasses = match.group(3);
      
      // استخراج التعليق التوثيقي للكلاس
      final classStart = match.start;
      final commentEnd = classStart;
      final commentStart = content.lastIndexOf('///', commentEnd);
      String? comment;
      
      if (commentStart != -1 && commentStart < classStart) {
        comment = content.substring(commentStart, commentEnd).trim();
      }
      
      // استخراج الدوال في الكلاس
      final classContent = _extractClassContent(content, classStart);
      final methods = _extractMethods(classContent);
      
      classes.add(ClassInfo(
        name: className,
        extendsClass: extendsClass,
        implementsClasses: implementsClasses,
        comment: comment,
        methods: methods,
      ));
    }
    
    return classes;
  }
  
  /// استخراج محتوى الكلاس
  /// 
  /// @param content محتوى الملف
  /// @param classStart موقع بداية الكلاس
  /// @return محتوى الكلاس
  String _extractClassContent(String content, int classStart) {
    int openBraces = 0;
    int closeBraces = 0;
    int currentPos = classStart;
    
    // البحث عن بداية الكلاس
    while (currentPos < content.length && content[currentPos] != '{') {
      currentPos++;
    }
    
    if (currentPos >= content.length) {
      return '';
    }
    
    final contentStart = currentPos;
    openBraces = 1;
    
    // البحث عن نهاية الكلاس
    while (currentPos < content.length && openBraces > closeBraces) {
      currentPos++;
      
      if (currentPos < content.length) {
        if (content[currentPos] == '{') {
          openBraces++;
        } else if (content[currentPos] == '}') {
          closeBraces++;
        }
      }
    }
    
    if (currentPos >= content.length) {
      return content.substring(contentStart);
    }
    
    return content.substring(contentStart, currentPos + 1);
  }
  
  /// استخراج الدوال من محتوى الكلاس
  /// 
  /// @param classContent محتوى الكلاس
  /// @return قائمة بالدوال
  List<MethodInfo> _extractMethods(String classContent) {
    final methods = <MethodInfo>[];
    final methodRegex = RegExp(r'(?:\/\/\/[^}]*?)?\s*(?:static\s+)?(?:final\s+)?(?:[\w<>?]+\s+)+(\w+)\s*\(([^)]*)\)');
    final matches = methodRegex.allMatches(classContent);
    
    for (final match in matches) {
      final methodName = match.group(1) ?? '';
      final parameters = match.group(2) ?? '';
      
      // استخراج التعليق التوثيقي للدالة
      final methodStart = match.start;
      final commentEnd = methodStart;
      final commentStart = classContent.lastIndexOf('///', commentEnd);
      String? comment;
      
      if (commentStart != -1 && commentStart < methodStart) {
        comment = classContent.substring(commentStart, commentEnd).trim();
      }
      
      methods.add(MethodInfo(
        name: methodName,
        parameters: parameters,
        comment: comment,
      ));
    }
    
    return methods;
  }
  
  /// استخراج الدوال من محتوى الملف
  /// 
  /// @param content محتوى الملف
  /// @return قائمة بالدوال
  List<FunctionInfo> _extractFunctions(String content) {
    final functions = <FunctionInfo>[];
    final functionRegex = RegExp(r'(?:\/\/\/[^}]*?)?\s*(?:[\w<>?]+\s+)+(\w+)\s*\(([^)]*)\)(?:\s*async)?(?:\s*\{)');
    final matches = functionRegex.allMatches(content);
    
    for (final match in matches) {
      final functionName = match.group(1) ?? '';
      final parameters = match.group(2) ?? '';
      
      // استخراج التعليق التوثيقي للدالة
      final functionStart = match.start;
      final commentEnd = functionStart;
      final commentStart = content.lastIndexOf('///', commentEnd);
      String? comment;
      
      if (commentStart != -1 && commentStart < functionStart) {
        comment = content.substring(commentStart, commentEnd).trim();
      }
      
      functions.add(FunctionInfo(
        name: functionName,
        parameters: parameters,
        comment: comment,
      ));
    }
    
    return functions;
  }
  
  /// توليد توثيق Markdown للملف
  /// 
  /// @param fileName اسم الملف
  /// @param content محتوى الملف
  /// @param classes قائمة بالكلاسات
  /// @param functions قائمة بالدوال
  /// @return توثيق Markdown للملف
  String _generateFileMarkdown(
    String fileName,
    String content,
    List<ClassInfo> classes,
    List<FunctionInfo> functions,
  ) {
    final buffer = StringBuffer();
    
    // عنوان الملف
    buffer.writeln('# $fileName');
    buffer.writeln();
    
    // وصف الملف
    final fileComment = _extractFileComment(content);
    if (fileComment != null) {
      buffer.writeln(fileComment);
      buffer.writeln();
    }
    
    // قائمة المحتويات
    buffer.writeln('## جدول المحتويات');
    buffer.writeln();
    
    if (classes.isNotEmpty) {
      buffer.writeln('### الكلاسات');
      buffer.writeln();
      
      for (final classInfo in classes) {
        buffer.writeln('- [${classInfo.name}](#${classInfo.name.toLowerCase()})');
      }
      
      buffer.writeln();
    }
    
    if (functions.isNotEmpty) {
      buffer.writeln('### الدوال');
      buffer.writeln();
      
      for (final functionInfo in functions) {
        buffer.writeln('- [${functionInfo.name}](#${functionInfo.name.toLowerCase()})');
      }
      
      buffer.writeln();
    }
    
    // توثيق الكلاسات
    if (classes.isNotEmpty) {
      buffer.writeln('## الكلاسات');
      buffer.writeln();
      
      for (final classInfo in classes) {
        buffer.writeln('### ${classInfo.name}');
        buffer.writeln();
        
        if (classInfo.comment != null) {
          buffer.writeln(_formatComment(classInfo.comment!));
          buffer.writeln();
        }
        
        if (classInfo.extendsClass != null) {
          buffer.writeln('**يرث من:** ${classInfo.extendsClass}');
          buffer.writeln();
        }
        
        if (classInfo.implementsClasses != null) {
          buffer.writeln('**ينفذ:** ${classInfo.implementsClasses}');
          buffer.writeln();
        }
        
        if (classInfo.methods.isNotEmpty) {
          buffer.writeln('#### الدوال');
          buffer.writeln();
          
          for (final methodInfo in classInfo.methods) {
            buffer.writeln('##### ${methodInfo.name}');
            buffer.writeln();
            
            if (methodInfo.comment != null) {
              buffer.writeln(_formatComment(methodInfo.comment!));
              buffer.writeln();
            }
            
            buffer.writeln('```dart');
            buffer.writeln('${methodInfo.name}(${methodInfo.parameters})');
            buffer.writeln('```');
            buffer.writeln();
          }
        }
      }
    }
    
    // توثيق الدوال
    if (functions.isNotEmpty) {
      buffer.writeln('## الدوال');
      buffer.writeln();
      
      for (final functionInfo in functions) {
        buffer.writeln('### ${functionInfo.name}');
        buffer.writeln();
        
        if (functionInfo.comment != null) {
          buffer.writeln(_formatComment(functionInfo.comment!));
          buffer.writeln();
        }
        
        buffer.writeln('```dart');
        buffer.writeln('${functionInfo.name}(${functionInfo.parameters})');
        buffer.writeln('```');
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }
  
  /// استخراج تعليق الملف
  /// 
  /// @param content محتوى الملف
  /// @return تعليق الملف
  String? _extractFileComment(String content) {
    final fileCommentRegex = RegExp(r'\/\*\*\s*\n\s*\*\s*@file[^*]*\*\/');
    final match = fileCommentRegex.firstMatch(content);
    
    if (match != null) {
      return _formatComment(match.group(0)!);
    }
    
    return null;
  }
  
  /// تنسيق التعليق
  /// 
  /// @param comment التعليق
  /// @return التعليق المنسق
  String _formatComment(String comment) {
    // إزالة علامات التعليق
    String formatted = comment.replaceAll(RegExp(r'\/\*\*|\*\/|\/\/\/|\*'), '');
    
    // إزالة المسافات الزائدة
    formatted = formatted.split('\n').map((line) => line.trim()).join('\n');
    
    // تنسيق وسوم التوثيق
    formatted = formatted.replaceAll('@param', '**المعلمة:**');
    formatted = formatted.replaceAll('@return', '**الإرجاع:**');
    formatted = formatted.replaceAll('@throws', '**يرمي:**');
    formatted = formatted.replaceAll('@see', '**انظر:**');
    formatted = formatted.replaceAll('@deprecated', '**مهمل:**');
    formatted = formatted.replaceAll('@since', '**منذ:**');
    formatted = formatted.replaceAll('@author', '**المؤلف:**');
    formatted = formatted.replaceAll('@version', '**الإصدار:**');
    formatted = formatted.replaceAll('@file', '**الملف:**');
    formatted = formatted.replaceAll('@brief', '**ملخص:**');
    formatted = formatted.replaceAll('@date', '**التاريخ:**');
    
    return formatted.trim();
  }
  
  /// توليد ملف README.md
  /// 
  /// @return true إذا تم توليد الملف بنجاح، false خلاف ذلك
  Future<bool> _generateReadme() async {
    try {
      final readmeFile = File(path.join(docsPath, 'README.md'));
      final buffer = StringBuffer();
      
      buffer.writeln('# توثيق مشروع MPay');
      buffer.writeln();
      buffer.writeln('## نظرة عامة');
      buffer.writeln();
      buffer.writeln('هذا التوثيق يغطي مشروع MPay، وهو تطبيق للدفع الإلكتروني يوفر واجهة سهلة الاستخدام للمستخدمين لإدارة محافظهم الإلكترونية وإجراء المعاملات المالية.');
      buffer.writeln();
      buffer.writeln('## هيكل المشروع');
      buffer.writeln();
      buffer.writeln('يتبع المشروع نمط Clean Architecture مع فصل واضح بين الطبقات:');
      buffer.writeln();
      buffer.writeln('- **طبقة العرض (Presentation Layer)**: تحتوي على واجهات المستخدم والشاشات والمكونات المرئية');
      buffer.writeln('- **طبقة المنطق التجاري (Domain Layer)**: تحتوي على الكيانات الأساسية وقواعد العمل وواجهات المستودعات');
      buffer.writeln('- **طبقة البيانات (Data Layer)**: تحتوي على تنفيذ المستودعات ومصادر البيانات');
      buffer.writeln();
      buffer.writeln('للمزيد من التفاصيل، راجع [هيكل المشروع](project_structure.md).');
      buffer.writeln();
      buffer.writeln('## الوثائق');
      buffer.writeln();
      buffer.writeln('- [فهرس التوثيق](index.md)');
      buffer.writeln('- [هيكل المشروع](project_structure.md)');
      buffer.writeln();
      buffer.writeln('## المتطلبات');
      buffer.writeln();
      buffer.writeln('- Flutter SDK 3.0.0 أو أحدث');
      buffer.writeln('- Dart SDK 3.0.0 أو أحدث');
      buffer.writeln();
      buffer.writeln('## التثبيت');
      buffer.writeln();
      buffer.writeln('```bash');
      buffer.writeln('flutter pub get');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('## التشغيل');
      buffer.writeln();
      buffer.writeln('```bash');
      buffer.writeln('flutter run');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('## الاختبار');
      buffer.writeln();
      buffer.writeln('```bash');
      buffer.writeln('flutter test');
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('## المساهمة');
      buffer.writeln();
      buffer.writeln('يرجى قراءة [دليل المساهمة](CONTRIBUTING.md) للحصول على تفاصيل حول عملية تقديم طلبات السحب.');
      buffer.writeln();
      buffer.writeln('## الترخيص');
      buffer.writeln();
      buffer.writeln('هذا المشروع مرخص بموجب ترخيص MIT - راجع ملف [LICENSE](LICENSE) للحصول على التفاصيل.');
      
      await readmeFile.writeAsString(buffer.toString());
      
      return true;
    } catch (e) {
      print('خطأ في توليد ملف README.md: $e');
      return false;
    }
  }
  
  /// توليد ملف هيكل المشروع
  /// 
  /// @return true إذا تم توليد الملف بنجاح، false خلاف ذلك
  Future<bool> _generateProjectStructure() async {
    try {
      final structureFile = File(path.join(docsPath, 'project_structure.md'));
      final buffer = StringBuffer();
      
      buffer.writeln('# هيكل مشروع MPay');
      buffer.writeln();
      buffer.writeln('## نظرة عامة');
      buffer.writeln();
      buffer.writeln('يتبع المشروع نمط Clean Architecture مع فصل واضح بين الطبقات:');
      buffer.writeln();
      buffer.writeln('- **طبقة العرض (Presentation Layer)**: تحتوي على واجهات المستخدم والشاشات والمكونات المرئية');
      buffer.writeln('- **طبقة المنطق التجاري (Domain Layer)**: تحتوي على الكيانات الأساسية وقواعد العمل وواجهات المستودعات');
      buffer.writeln('- **طبقة البيانات (Data Layer)**: تحتوي على تنفيذ المستودعات ومصادر البيانات');
      buffer.writeln();
      buffer.writeln('## هيكل المجلدات');
      buffer.writeln();
      buffer.writeln('```');
      
      // توليد هيكل المجلدات
      final structure = await _generateDirectoryStructure(projectPath);
      buffer.writeln(structure);
      
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('## وصف المجلدات');
      buffer.writeln();
      buffer.writeln('### lib/');
      buffer.writeln();
      buffer.writeln('المجلد الرئيسي للكود المصدري.');
      buffer.writeln();
      buffer.writeln('### lib/presentation/');
      buffer.writeln();
      buffer.writeln('يحتوي على طبقة العرض، بما في ذلك الشاشات والمكونات المرئية.');
      buffer.writeln();
      buffer.writeln('### lib/domain/');
      buffer.writeln();
      buffer.writeln('يحتوي على طبقة المنطق التجاري، بما في ذلك الكيانات وواجهات المستودعات وحالات الاستخدام.');
      buffer.writeln();
      buffer.writeln('### lib/data/');
      buffer.writeln();
      buffer.writeln('يحتوي على طبقة البيانات، بما في ذلك تنفيذ المستودعات ومصادر البيانات.');
      buffer.writeln();
      buffer.writeln('### lib/core/');
      buffer.writeln();
      buffer.writeln('يحتوي على المكونات الأساسية المشتركة بين جميع الطبقات.');
      buffer.writeln();
      buffer.writeln('### lib/utils/');
      buffer.writeln();
      buffer.writeln('يحتوي على الأدوات المساعدة والوظائف المشتركة.');
      buffer.writeln();
      buffer.writeln('### test/');
      buffer.writeln();
      buffer.writeln('يحتوي على اختبارات الوحدة والتكامل.');
      buffer.writeln();
      buffer.writeln('### assets/');
      buffer.writeln();
      buffer.writeln('يحتوي على الموارد الثابتة مثل الصور وملفات الترجمة.');
      
      await structureFile.writeAsString(buffer.toString());
      
      return true;
    } catch (e) {
      print('خطأ في توليد ملف هيكل المشروع: $e');
      return false;
    }
  }
  
  /// توليد هيكل المجلدات
  /// 
  /// @param dirPath مسار المجلد
  /// @param prefix بادئة السطر
  /// @param isLast هل هذا آخر عنصر في المجلد الحالي
  /// @return هيكل المجلدات
  Future<String> _generateDirectoryStructure(
    String dirPath, {
    String prefix = '',
    bool isLast = true,
  }) async {
    final buffer = StringBuffer();
    final dir = Directory(dirPath);
    final entities = await dir.list().toList();
    
    // ترتيب العناصر: المجلدات أولاً ثم الملفات
    entities.sort((a, b) {
      final aIsDir = a is Directory;
      final bIsDir = b is Directory;
      
      if (aIsDir && !bIsDir) {
        return -1;
      } else if (!aIsDir && bIsDir) {
        return 1;
      } else {
        return path.basename(a.path).compareTo(path.basename(b.path));
      }
    });
    
    // تصفية العناصر المستثناة
    final filteredEntities = entities.where((entity) {
      final name = path.basename(entity.path);
      
      if (entity is Directory) {
        return !ignoredFolders.contains(name);
      } else if (entity is File) {
        return !ignoredFiles.contains(name);
      }
      
      return true;
    }).toList();
    
    // طباعة اسم المجلد الحالي
    final dirName = path.basename(dirPath);
    buffer.writeln('$prefix$dirName/');
    
    // طباعة محتويات المجلد
    for (var i = 0; i < filteredEntities.length; i++) {
      final entity = filteredEntities[i];
      final isLastEntity = i == filteredEntities.length - 1;
      final newPrefix = prefix + (isLast ? '    ' : '│   ');
      final entityPrefix = newPrefix + (isLastEntity ? '└── ' : '├── ');
      
      if (entity is Directory) {
        // طباعة هيكل المجلد الفرعي
        buffer.write(await _generateDirectoryStructure(
          entity.path,
          prefix: entityPrefix,
          isLast: isLastEntity,
        ));
      } else if (entity is File) {
        // طباعة اسم الملف
        buffer.writeln('$entityPrefix${path.basename(entity.path)}');
      }
    }
    
    return buffer.toString();
  }
}

/// معلومات الملف
class FileInfo {
  /// اسم الملف
  final String fileName;
  
  /// قائمة بالكلاسات
  final List<ClassInfo> classes;
  
  /// قائمة بالدوال
  final List<FunctionInfo> functions;
  
  /// توثيق الملف
  final String documentation;
  
  /// إنشاء مثيل جديد من معلومات الملف
  /// 
  /// @param fileName اسم الملف
  /// @param classes قائمة بالكلاسات
  /// @param functions قائمة بالدوال
  /// @param documentation توثيق الملف
  FileInfo({
    required this.fileName,
    required this.classes,
    required this.functions,
    required this.documentation,
  });
}

/// معلومات الكلاس
class ClassInfo {
  /// اسم الكلاس
  final String name;
  
  /// الكلاس الذي يرث منه
  final String? extendsClass;
  
  /// الواجهات التي ينفذها
  final String? implementsClasses;
  
  /// تعليق الكلاس
  final String? comment;
  
  /// قائمة بالدوال
  final List<MethodInfo> methods;
  
  /// إنشاء مثيل جديد من معلومات الكلاس
  /// 
  /// @param name اسم الكلاس
  /// @param extendsClass الكلاس الذي يرث منه
  /// @param implementsClasses الواجهات التي ينفذها
  /// @param comment تعليق الكلاس
  /// @param methods قائمة بالدوال
  ClassInfo({
    required this.name,
    this.extendsClass,
    this.implementsClasses,
    this.comment,
    required this.methods,
  });
}

/// معلومات الدالة
class MethodInfo {
  /// اسم الدالة
  final String name;
  
  /// معلمات الدالة
  final String parameters;
  
  /// تعليق الدالة
  final String? comment;
  
  /// إنشاء مثيل جديد من معلومات الدالة
  /// 
  /// @param name اسم الدالة
  /// @param parameters معلمات الدالة
  /// @param comment تعليق الدالة
  MethodInfo({
    required this.name,
    required this.parameters,
    this.comment,
  });
}

/// معلومات الدالة
class FunctionInfo {
  /// اسم الدالة
  final String name;
  
  /// معلمات الدالة
  final String parameters;
  
  /// تعليق الدالة
  final String? comment;
  
  /// إنشاء مثيل جديد من معلومات الدالة
  /// 
  /// @param name اسم الدالة
  /// @param parameters معلمات الدالة
  /// @param comment تعليق الدالة
  FunctionInfo({
    required this.name,
    required this.parameters,
    this.comment,
  });
}
