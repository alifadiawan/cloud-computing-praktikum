class AccelSample {
  final String t;
  final double x;
  final double y;
  final double z;

  AccelSample({
    required this.t,
    required this.x,
    required this.y,
    required this.z,
  });

  // Konversi dari objek Dart ke JSON (untuk request body)
  Map<String, dynamic> toJson() => {
        "t": t,
        "x": x,
        "y": y,
        "z": z,
      };

  // Konversi dari JSON ke objek Dart (untuk response data)
  factory AccelSample.fromJson(Map<String, dynamic> json) => AccelSample(
        t: json["t"],
        x: (json["x"] as num).toDouble(),
        y: (json["y"] as num).toDouble(),
        z: (json["z"] as num).toDouble(),
      );
}