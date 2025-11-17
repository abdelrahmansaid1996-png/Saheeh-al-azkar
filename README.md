# Azkar Flutter Skeleton

هذا مشروع Flutter جاهز للبناء (skeleton) لتطبيق أذكار. المشروع يحتوي على:
- عرض أقسام الأذكار
- شاشة عرض الذكر والعداد
- حفظ المفضلات باستخدام SharedPreferences
- TTS (flutter_tts)
- مثال assets/azkar.json مع أمثلة

## ملاحظات هامة
- **لا يمكنني بناء APK داخل هذا بيئة** لعدم وجود Flutter SDK هنا. ولكن يمكنك بناء APK بسهولة محليًا أو استخدام GitHub Actions (تجد ملف workflow مرفق).
- التعليمات أدناه تشرح كيف تبني APK محليًا وكيف تشغّل GitHub Actions.

## تشغيل محلي
1. ثبت Flutter على جهازك: https://flutter.dev/docs/get-started/install
2. انسخ المشروع إلى جهازك أو فكّ ضغط الملف ZIP.
3. افتح طرفية في مجلد المشروع، ثم شغّل:
   ```
   flutter pub get
   flutter run
   ```
4. لبناء APK مُوقّع (release):
   - اتبع https://flutter.dev/docs/deployment/android#create-a-keystore
   - ثم:
     ```
     flutter build apk --release
     ```

## GitHub Actions (مرفق)
- أرفقت workflow في `.github/workflows/flutter.yml`. بعد رفع الريبو إلى GitHub وتفعيل Actions، سيبني APK ويصدره كـ artifact تلقائيًا.

## تخصيص المحتوى
- ضع ملفك `assets/azkar.json` الكامل (أو سأستخرجه لك من PDF لو رغبت) مكان الملف الموجود.
- ثم شغّل `flutter pub get` واعمل run.

---
