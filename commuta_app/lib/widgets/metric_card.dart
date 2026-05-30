import 'package:flutter/material.dart';
import '../core/constants/app_colours.dart';
import '../core/utils/daqi_utils.dart';

/// A single air quality metric card.
///
/// Displays the metric label, current value (coloured by DAQI band),
/// unit, a DAQI band pill, and an (i) icon that opens the info bottom sheet.
///
/// Pass [daqiInfo] as null to render an unavailable state (shows '—').
class MetricCard extends StatelessWidget {
  final String label;
  final String unit;
  final String? value;       // null or '—' renders unavailable state
  final DaqiInfo? daqiInfo;  // null = unavailable / no banding
  final VoidCallback onInfoTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.daqiInfo,
    required this.onInfoTap,
  });

  bool get _isAvailable => value != null && value != '—';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColours.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + (i) icon ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColours.textSecondary,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onInfoTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColours.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Value + unit ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isAvailable ? value! : '—',
                style: TextStyle(
                  fontSize: _isAvailable ? 24 : 22,
                  fontWeight: FontWeight.w600,
                  color: _isAvailable
                      ? (daqiInfo?.colour ?? AppColours.textPrimary)
                      : AppColours.textSecondary,
                  height: 1.1,
                ),
              ),
              if (_isAvailable) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColours.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // ── DAQI band pill ────────────────────────────────────────────────
          if (_isAvailable && daqiInfo != null)
            _DaqiBandPill(daqiInfo: daqiInfo!)
          else
            const SizedBox(height: 20), // maintain consistent card height
        ],
      ),
    );
  }
}

class _DaqiBandPill extends StatelessWidget {
  final DaqiInfo daqiInfo;

  const _DaqiBandPill({required this.daqiInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: daqiInfo.colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: daqiInfo.colour,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            daqiInfo.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: daqiInfo.colour,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}