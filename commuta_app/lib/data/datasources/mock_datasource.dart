import 'dart:async';
import 'dart:math';
import '../models/air_quality_reading.dart';
import 'air_quality_datasource.dart';

/// Mock implementation of [AirQualityDataSource].
/// Emits realistic-looking readings so the UI can be built and tested
/// before BLE is wired up. Swap this for BLEDataSource when ready.
class MockDataSource implements AirQualityDataSource {
  final Random _random = Random();
  StreamController<AirQualityReading>? _controller;
  Timer? _timer;
  int _sequence = 0;

  // Simulated "current" values that drift slightly each tick
  double _pm1   = 8.2;
  double _pm25  = 14.5;
  double _pm10  = 22.1;
  double _co2   = 612.0;
  double _temp  = 21.4;
  double _hum   = 48.0;
  double _pres  = 1013.2;

  AirQualityReading _buildReading() {
    // Small random walk so the UI doesn't look completely static
    _pm1   = (_pm1   + (_random.nextDouble() - 0.5) * 1.0).clamp(2.0,  80.0);
    _pm25  = (_pm25  + (_random.nextDouble() - 0.5) * 1.5).clamp(3.0, 150.0);
    _pm10  = (_pm10  + (_random.nextDouble() - 0.5) * 2.0).clamp(5.0, 200.0);
    _co2   = (_co2   + (_random.nextDouble() - 0.5) * 20.0).clamp(400.0, 2000.0);
    _temp  = (_temp  + (_random.nextDouble() - 0.5) * 0.3).clamp(10.0,  40.0);
    _hum   = (_hum   + (_random.nextDouble() - 0.5) * 1.0).clamp(10.0, 100.0);
    _pres  = (_pres  + (_random.nextDouble() - 0.5) * 0.5).clamp(950.0, 1050.0);

    _sequence++;
    return AirQualityReading(
      timestamp:      DateTime.now(),
      pm1:            double.parse(_pm1.toStringAsFixed(1)),
      pm25:           double.parse(_pm25.toStringAsFixed(1)),
      pm10:           double.parse(_pm10.toStringAsFixed(1)),
      co2:            double.parse(_co2.toStringAsFixed(0)),
      temperature:    double.parse(_temp.toStringAsFixed(1)),
      humidity:       double.parse(_hum.toStringAsFixed(1)),
      pressure:       double.parse(_pres.toStringAsFixed(1)),
      nox:            null, // SGP41 not yet connected
      tvoc:           null, // SGP41 not yet connected
      sourceFlag:     'mock',
      sequenceNumber: _sequence,
    );
  }

  @override
  Stream<AirQualityReading> subscribeToLiveReadings() {
    _controller?.close();
    _controller = StreamController<AirQualityReading>.broadcast();

    // Emit immediately, then every 10 seconds — matches real device cadence
    _controller!.add(_buildReading());
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_controller?.isClosed == false) {
        _controller!.add(_buildReading());
      }
    });

    return _controller!.stream;
  }

  @override
  Future<AirQualityReading?> getLatestReading() async {
    return _buildReading();
  }

  @override
  Future<List<AirQualityReading>> getHistoricalReadings({
    required DateTime from,
    required DateTime to,
  }) async {
    // Generate a plausible history at 10-second intervals for the History screen
    final readings = <AirQualityReading>[];
    DateTime cursor = from;
    while (cursor.isBefore(to)) {
      readings.add(_buildReading());
      cursor = cursor.add(const Duration(seconds: 10));
    }
    return readings;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }
}