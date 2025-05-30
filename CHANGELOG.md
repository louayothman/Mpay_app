# سجل التغييرات

جميع التغييرات الهامة في هذا المشروع سيتم توثيقها في هذا الملف.

## [1.0.0] - 2025-04-17

### إصلاحات أمنية

- استبدال خوارزمية XOR البسيطة للتشفير بمكتبة تشفير قياسية AES
- إضافة آلية للتحقق من سلامة البيانات المشفرة (HMAC)
- تنفيذ التحقق من شهادات SSL/TLS وتثبيت الشهادات
- تأمين تخزين بيانات المستخدم الحساسة باستخدام flutter_secure_storage
- تنفيذ آلية للحماية من هجمات CSRF
- تخزين محاولات تسجيل الدخول في تخزين دائم بدلاً من الذاكرة فقط
- توحيد آليات حظر تسجيل الدخول في مكان واحد
- استخدام مقارنة ثابتة الوقت للرموز الأمنية
- تحسين طريقة تسجيل الأخطاء لتجنب طباعة معلومات حساسة
- تأمين عناوين URL الثابتة للواجهات البرمجية
- إضافة التحقق من صحة عناوين المحافظ المشفرة
- إضافة آلية لطلب تأكيد إضافي للمعاملات الكبيرة
- تنفيذ آلية لإنهاء الجلسات غير النشطة
- إضافة آلية لتجديد رموز المصادقة بشكل دوري
- تحسين رسائل الخطأ لتجنب كشف معلومات حساسة
- إضافة تحقق من الصلاحيات قبل العمليات الحساسة
- استبدال SharedPreferences بـ flutter_secure_storage لتخزين البيانات الحساسة
- تحسين التحقق من مدخلات المستخدم
- إزالة الاعتمادات المخزنة في التعليمات البرمجية

### تحسينات الأداء

- تحسين التعامل مع موارد الصور وتحديد حجمها قبل تحميلها
- تحسين استخدام ListView.builder وتجنب shrinkWrap: true
- إصلاح تسريب الذاكرة في مكونات FutureBuilder وStreamBuilder
- تحسين استخدام deferFirstFrame
- تقليل إعادة بناء الواجهة المتكررة
- استخدام const للويدجت الثابتة
- تنفيذ التحميل المتأخر للبيانات بشكل فعال
- تحسين استخدام التخزين المؤقت
- تقليل استخدام الرسوم المتحركة غير الضرورية
- إيقاف الرسوم المتحركة عند عدم الحاجة إليها
- تحسين استخدام الذاكرة للصور
- تحسين استخدام وحدة المعالجة المركزية
- تحسين استخدام الشبكة
- تحسين استخدام البطارية
- تقليل استخدام setState
- استخدام const للمتغيرات الثابتة
- استخدام compute للعمليات الثقيلة
- تحسين استخدام async و await
- تحسين تحرير الموارد
- تحسين استخدام didChangeDependencies

### تحسينات واجهة المستخدم والتجربة

- استبدال القيم الثابتة للتصميم بنهج أكثر مرونة
- تحسين استخدام Semantics
- إضافة وصف للصور
- تحسين دعم وضع التباين العالي
- تحسين التغذية الراجعة للمستخدم
- تحسين التعامل مع الشاشات الكبيرة
- استخدام LayoutBuilder بشكل أفضل
- تحسين دعم تكبير النص
- توفير حالات التحميل والخطأ والفارغة
- إضافة إرشادات للمستخدم
- إضافة دعم لوضع الشاشة المقسمة
- تحسين التعامل مع تغيير اتجاه الشاشة
- إضافة تعليقات توضيحية للحقول
- إضافة خيارات تخصيص للمستخدم
- تحسين دعم اللغات المختلفة
- توحيد استخدام الألوان
- توحيد استخدام الخطوط
- توحيد استخدام المسافات
- توحيد استخدام نصف القطر
- توحيد استخدام الظلال

### تحسينات أفضل الممارسات

- تطبيق مبدأ المسؤولية الواحدة
- استخدام واجهات البرمجة (Interfaces)
- تنفيذ نمط Repository
- تحسين استخدام Dependency Injection
- إضافة إطار عمل للاختبارات
- توحيد أسلوب التسمية
- استخدام أسماء معبرة بدلاً من التعليقات
- استخدام الثوابت المسماة بدلاً من القيم الحرفية
- استخدام Enums بدلاً من السلاسل النصية
- إضافة توثيق للواجهات العامة
- تنفيذ نمط الكائن المجرد (Abstract Factory)
- استخدام Extension Methods
- إضافة توثيق للكلاسات
- إضافة توثيق للمتغيرات
- إنشاء ملف README.md
- إنشاء ملف CHANGELOG.md
- تحسين استخدام Provider
- تنفيذ نمط BLoC
- تطبيق نمط التصميم القابل للاختبار
- تنفيذ نمط Result

## [0.9.0] - 2025-03-15

### الميزات الجديدة

- إضافة دعم للمدفوعات عبر QR
- إضافة دعم للمحافظ المتعددة
- إضافة دعم للعملات المتعددة
- إضافة دعم للإشعارات المخصصة

### التحسينات

- تحسين واجهة المستخدم
- تحسين أداء التطبيق
- تحسين استخدام البطارية

### إصلاحات

- إصلاح مشكلة في تسجيل الدخول
- إصلاح مشكلة في عرض المعاملات
- إصلاح مشكلة في إعدادات التطبيق

## [0.8.0] - 2025-02-01

### الميزات الجديدة

- إضافة دعم للمصادقة البيومترية
- إضافة دعم للمعاملات المجدولة
- إضافة دعم للتقارير المالية

### التحسينات

- تحسين أمان التطبيق
- تحسين سرعة المعاملات
- تحسين واجهة المستخدم

### إصلاحات

- إصلاح مشكلة في تخزين البيانات
- إصلاح مشكلة في عرض الرسوم البيانية
- إصلاح مشكلة في إعدادات الإشعارات

## [0.7.0] - 2025-01-01

### الميزات الجديدة

- إطلاق النسخة التجريبية الأولى
- دعم المدفوعات الأساسية
- دعم إدارة الحسابات
- دعم إدارة المستخدمين
