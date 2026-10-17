import 'dart:math';

/// Direction of the Kaaba in Makkah, in degrees clockwise from true North.
double qiblaBearing(double lat, double lng) {
  const kaabaLat = 21.4225;
  const kaabaLng = 39.8262;
  final phi1 = lat * pi / 180;
  final phi2 = kaabaLat * pi / 180;
  final dLng = (kaabaLng - lng) * pi / 180;
  final y = sin(dLng) * cos(phi2);
  final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLng);
  final deg = atan2(y, x) * 180 / pi;
  return (deg + 360) % 360;
}
