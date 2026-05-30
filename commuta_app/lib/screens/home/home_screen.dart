import 'package:flutter/material.dart';
import '../../core/constants/app_colours.dart';
import '../../core/utils/daqi_utils.dart';
import '../../data/datasources/mock_datasource.dart';
import '../../data/datasources/air_quality_datasource.dart';
import '../../data/models/air_quality_reading.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/metric_info_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Swap MockDataSource for BLEDataSource here when BLE is ready
  final AirQualityDataSource _dataSource = MockDataSource();

  AirQualityReading? _latestReading;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToReadings();
  }

  void _subscribeToReadings() {
    _dataSource.subscribeToLiveReadings().listen((reading) {
      if (mounted) {
        setState(() {
          _latestReading = reading;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _dataSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColours.accent,
                strokeWidth: 2,
              ),
            )
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final reading = _latestReading!;
    final overallDaqi = DaqiUtils.overallDaqi(reading.pm25, reading.pm10);

    return RefreshIndicator(
      color: AppColours.accent,
      onRefresh: () async {
        final fresh = await _dataSource.getLatestReading();
        if (mounted && fresh != null) {
          setState(() => _latestReading = fresh);
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero DAQI card ───────────────────────────────────────
                _HeroDaqiCard(
                  daqiInfo:    overallDaqi,
                  lastUpdated: reading.timestamp,
                ),

                const SizedBox(height: 20),

                // ── Section label ────────────────────────────────────────
                const _SectionLabel(text: 'Readings'),

                const SizedBox(height: 12),

                // ── Metric cards grid ────────────────────────────────────
                _MetricGrid(reading: reading, onInfoTap: _showInfoSheet),

                const SizedBox(height: 20),

                // ── Local weather + outdoor AQI card ─────────────────────
                const _WeatherCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet({
    required String label,
    required String unit,
    required String? value,
    required DaqiInfo? daqiInfo,
  }) {
    MetricInfoSheet.show(
      context,
      metricLabel:  label,
      unit:         unit,
      currentValue: value,
      daqiInfo:     daqiInfo,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero DAQI card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroDaqiCard extends StatelessWidget {
  final DaqiInfo daqiInfo;
  final DateTime lastUpdated;

  const _HeroDaqiCard({
    required this.daqiInfo,
    required this.lastUpdated,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColours.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ────────────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Overall Air Quality',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColours.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                'Updated ${_formatTime(lastUpdated)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColours.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Band name ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Colour swatch circle
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: daqiInfo.colour,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                daqiInfo.label,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: daqiInfo.colour,
                  height: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── DAQI band row (1–10 numeric scale, UK DAQI) ──────────────────
          _DaqiBandBar(currentBand: daqiInfo.band),
        ],
      ),
    );
  }
}

/// Visual DAQI 1–10 band bar with the current band highlighted.
/// UK DAQI uses a 10-point scale: 1–3 Low, 4–6 Moderate, 7–9 High, 10 Very High.
class _DaqiBandBar extends StatelessWidget {
  final DaqiBand currentBand;

  const _DaqiBandBar({required this.currentBand});

  static const _bands = [
    (label: 'Low',       colour: AppColours.daqiLow,      count: 3),
    (label: 'Moderate',  colour: AppColours.daqiModerate,  count: 3),
    (label: 'High',      colour: AppColours.daqiHigh,      count: 3),
    (label: 'Very High', colour: AppColours.daqiVeryHigh,  count: 1),
  ];

  DaqiBand _bandForIndex(int index) {
    if (index < 3)      return DaqiBand.low;
    if (index < 6)      return DaqiBand.moderate;
    if (index < 9)      return DaqiBand.high;
    return                     DaqiBand.veryHigh;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segment bar
        Row(
          children: List.generate(10, (i) {
            final segmentBand = _bandForIndex(i);
            final isActive = segmentBand == currentBand;
            final colour = switch (segmentBand) {
              DaqiBand.low      => AppColours.daqiLow,
              DaqiBand.moderate => AppColours.daqiModerate,
              DaqiBand.high     => AppColours.daqiHigh,
              DaqiBand.veryHigh => AppColours.daqiVeryHigh,
            };

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 9 ? 2 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? colour : colour.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.horizontal(
                    left:  i == 0 ? const Radius.circular(3) : Radius.zero,
                    right: i == 9 ? const Radius.circular(3) : Radius.zero,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),

        // Band labels below segments
        Row(
          children: _bands.map((b) {
            return Expanded(
              flex: b.count,
              child: Text(
                b.label,
                style: TextStyle(
                  fontSize: 9,
                  color: b.colour.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric cards grid
// ─────────────────────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  final AirQualityReading reading;
  final void Function({
    required String label,
    required String unit,
    required String? value,
    required DaqiInfo? daqiInfo,
  }) onInfoTap;

  const _MetricGrid({required this.reading, required this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    final metrics = _buildMetrics(reading);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:     2,
        crossAxisSpacing:  12,
        mainAxisSpacing:   12,
        childAspectRatio:  1.35,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return MetricCard(
          label:    m.label,
          unit:     m.unit,
          value:    m.value,
          daqiInfo: m.daqiInfo,
          onInfoTap: () => onInfoTap(
            label:    m.label,
            unit:     m.unit,
            value:    m.value,
            daqiInfo: m.daqiInfo,
          ),
        );
      },
    );
  }

  List<_MetricSpec> _buildMetrics(AirQualityReading r) {
    return [
      _MetricSpec(
        label:    'PM2.5',
        unit:     'µg/m³',
        value:    r.pm25.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forPm25(r.pm25),
      ),
      _MetricSpec(
        label:    'PM10',
        unit:     'µg/m³',
        value:    r.pm10.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forPm10(r.pm10),
      ),
      _MetricSpec(
        label:    'PM1',
        unit:     'µg/m³',
        value:    r.pm1.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forPm1(r.pm1),
      ),
      _MetricSpec(
        label:    'CO₂',
        unit:     'ppm',
        value:    r.co2.toStringAsFixed(0),
        daqiInfo: DaqiUtils.forCo2(r.co2),
      ),
      _MetricSpec(
        label:    'Temperature',
        unit:     '°C',
        value:    r.temperature.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forTemperature(r.temperature),
      ),
      _MetricSpec(
        label:    'Humidity',
        unit:     '%',
        value:    r.humidity.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forHumidity(r.humidity),
      ),
      _MetricSpec(
        label:    'Pressure',
        unit:     'hPa',
        value:    r.pressure.toStringAsFixed(1),
        daqiInfo: DaqiUtils.forPressure(r.pressure),
      ),
      _MetricSpec(
        label:    'NOx',
        unit:     'ppb',
        value:    r.nox != null ? r.nox!.toStringAsFixed(1) : '—',
        daqiInfo: DaqiUtils.forNox(r.nox),
      ),
      _MetricSpec(
        label:    'TVOC',
        unit:     'ppb',
        value:    r.tvoc != null ? r.tvoc!.toStringAsFixed(1) : '—',
        daqiInfo: DaqiUtils.forTvoc(r.tvoc),
      ),
    ];
  }
}

class _MetricSpec {
  final String label;
  final String unit;
  final String? value;
  final DaqiInfo? daqiInfo;

  const _MetricSpec({
    required this.label,
    required this.unit,
    required this.value,
    required this.daqiInfo,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Weather + outdoor AQI card (placeholder)
// ─────────────────────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColours.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: AppColours.daqiModerate,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local Weather & Outdoor AQI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColours.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // TODO: Wire up weather/outdoor AQI API (OpenWeather, IQAir, or DEFRA)
                  'Weather data coming soon',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColours.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColours.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }
}