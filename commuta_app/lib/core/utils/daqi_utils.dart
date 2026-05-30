import 'package:flutter/material.dart';
import '../constants/app_colours.dart';

/// DAQI (Daily Air Quality Index) banding as defined by DEFRA (UK).
///
/// PM2.5 and PM10 breakpoints verified against official gov.uk DAQI tables
/// (https://www.gov.uk/government/publications/uk-air-quality-index).
/// Based on 24-hour running mean concentration.
///
/// Note: DAQI is designed for outdoor ambient air. CO₂, temperature, humidity,
/// and pressure use non-DAQI indoor guidance thresholds — see individual comments.
enum DaqiBand {
  low,
  moderate,
  high,
  veryHigh,
}

class DaqiInfo {
  final DaqiBand band;
  final String label;
  final Color colour;

  const DaqiInfo({
    required this.band,
    required this.label,
    required this.colour,
  });
}

class DaqiUtils {
  DaqiUtils._();

  // ─── PM2.5 breakpoints (µg/m³, 24-hr running mean) ──────────────────────────
  // Source: gov.uk DAQI table. Low: 0–35, Moderate: 36–53, High: 54–70, Very High: 71+
  static DaqiInfo forPm25(double value) {
    if (value <= 35)       return _low;
    if (value <= 53)       return _moderate;
    if (value <= 70)       return _high;
    return                        _veryHigh;
  }

  // ─── PM10 breakpoints (µg/m³, 24-hr running mean) ────────────────────────────
  // Source: gov.uk DAQI table. Low: 0–50, Moderate: 51–75, High: 76–100, Very High: 101+
  static DaqiInfo forPm10(double value) {
    if (value <= 50)       return _low;
    if (value <= 75)       return _moderate;
    if (value <= 100)      return _high;
    return                        _veryHigh;
  }

  // ─── PM1 — no official DAQI band; use PM2.5 scale as a proxy ─────────────────
  static DaqiInfo forPm1(double value) => forPm25(value);

  // ─── CO₂ (ppm) — not part of DAQI; using common indoor air quality bands ─────
  // Source: CIBSE / ASHRAE indoor guidance (not DAQI).
  // TODO: Update if you find a more authoritative indoor CO₂ reference.
  static DaqiInfo forCo2(double value) {
    if (value <= 800)      return _low;
    if (value <= 1200)     return _moderate;
    if (value <= 1800)     return _high;
    return                        _veryHigh;
  }

  // ─── Temperature — neutral banding for display purposes only ─────────────────
  // No official health banding; pill is decorative only.
  static DaqiInfo forTemperature(double value) => _low;

  // ─── Humidity — comfort banding (no DAQI equivalent) ─────────────────────────
  // Based on general indoor comfort guidance (30–60% = comfortable).
  // TODO: Update if you find a more authoritative indoor humidity reference.
  static DaqiInfo forHumidity(double value) {
    if (value >= 30 && value <= 60) return _low;      // comfortable range
    if (value > 60 && value <= 75)  return _moderate;
    if (value > 75)                 return _high;
    return                                 _moderate; // below 30 also uncomfortable
  }

  // ─── Pressure — always neutral for display ────────────────────────────────────
  // No health banding applicable; pill is decorative only.
  static DaqiInfo forPressure(double value) => _low;

  // ─── NOx / TVOC — null means unavailable ─────────────────────────────────────
  static DaqiInfo? forNox(double? value) {
    if (value == null) return null;
    // TODO: Add NOx breakpoints when SGP41 is integrated
    return _low;
  }

  static DaqiInfo? forTvoc(double? value) {
    if (value == null) return null;
    // TODO: Add TVOC breakpoints when SGP41 is integrated
    return _low;
  }

  // ─── Overall DAQI — worst of PM2.5 and PM10 (primary DAQI pollutants) ────────
  static DaqiInfo overallDaqi(double pm25, double pm10) {
    final bands = [forPm25(pm25), forPm10(pm10)];
    return bands.reduce((a, b) => a.band.index >= b.band.index ? a : b);
  }

  // ─── Private band singletons ─────────────────────────────────────────────────
  static const DaqiInfo _low = DaqiInfo(
    band:   DaqiBand.low,
    label:  'Low',
    colour: AppColours.daqiLow,
  );
  static const DaqiInfo _moderate = DaqiInfo(
    band:   DaqiBand.moderate,
    label:  'Moderate',
    colour: AppColours.daqiModerate,
  );
  static const DaqiInfo _high = DaqiInfo(
    band:   DaqiBand.high,
    label:  'High',
    colour: AppColours.daqiHigh,
  );
  static const DaqiInfo _veryHigh = DaqiInfo(
    band:   DaqiBand.veryHigh,
    label:  'Very High',
    colour: AppColours.daqiVeryHigh,
  );
}