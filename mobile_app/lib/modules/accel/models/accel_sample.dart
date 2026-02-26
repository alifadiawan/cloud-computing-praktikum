// lib/modules/accel/models/accel_sample.dart

class AccelSample {
  final String t;
  final double x;
  final double y;
  final double z;
  final double timeInSeconds; // Tambahan untuk sumbu X grafik

  AccelSample({
    required this.t,
    required this.x,
    required this.y,
    required this.z,
    required this.timeInSeconds,
  });

  Map<String, dynamic> toJson() => {
        "t": t,
        "x": x,
        "y": y,
        "z": z,
      };

  factory AccelSample.fromJson(Map<String, dynamic> json) => AccelSample(
        t: json["t"],
        x: (json["x"] as num).toDouble(),
        y: (json["y"] as num).toDouble(),
        z: (json["z"] as num).toDouble(),
        timeInSeconds: 0.0, // Tidak terlalu butuh saat get latest
      );
}