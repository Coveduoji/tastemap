# AMap SDK uses reflection and native entry points. Follow the SDK keep rules:
# https://developer.amap.com/api/android-navi-sdk/guide/create-project/configuration-considerations
-keep class com.amap.api.maps.** { *; }
-keep class com.autonavi.** { *; }
-keep class com.amap.api.trace.** { *; }
-keep class com.amap.api.location.** { *; }
-keep class com.amap.api.fence.** { *; }
-keep class com.amap.api.services.** { *; }
-keep class com.amap.location.** { *; }
-keep class com.loc.** { *; }

# Exact missing-class rules emitted by R8 for the bundled AMap SDK.
-dontwarn com.amap.ams.gnss.GnssSoftLocator
-dontwarn net.jafama.FastMath
