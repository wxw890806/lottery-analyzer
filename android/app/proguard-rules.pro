# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep model classes
-keep class com.example.lottery_analyzer.models.** { *; }

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
