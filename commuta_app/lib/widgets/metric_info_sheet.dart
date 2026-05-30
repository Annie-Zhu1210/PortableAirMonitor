import 'package:flutter/material.dart';
import '../core/constants/app_colours.dart';
import '../core/utils/daqi_utils.dart';

/// Bottom sheet shown when the user taps the (i) icon on a metric card.
///
/// Currently a stub — sections are clearly marked TODO so they can be
/// filled in once pollutant explanations and health recommendations are
/// researched.
class MetricInfoSheet extends StatelessWidget {
  final String metricLabel;
  final String unit;
  final String? currentValue;
  final DaqiInfo? daqiInfo;

  const MetricInfoSheet({
    super.key,
    required this.metricLabel,
    required this.unit,
    this.currentValue,
    this.daqiInfo,
  });

  /// Convenience method to show this sheet from any widget.
  static void show(
    BuildContext context, {
    required String metricLabel,
    required String unit,
    String? currentValue,
    DaqiInfo? daqiInfo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MetricInfoSheet(
        metricLabel:  metricLabel,
        unit:         unit,
        currentValue: currentValue,
        daqiInfo:     daqiInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize:     0.4,
      maxChildSize:     0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColours.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColours.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header: metric name + current value ──────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      metricLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColours.textPrimary,
                      ),
                    ),
                  ),
                  if (currentValue != null && currentValue != '—') ...[
                    Text(
                      currentValue!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: daqiInfo?.colour ?? AppColours.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColours.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // ── What is this pollutant? ───────────────────────────────────
              _SectionHeader(title: 'What is $metricLabel?'),
              const SizedBox(height: 8),
              const _PlaceholderText(
                // TODO: Fill in pollutant explanation (1–2 sentences)
                text: 'Pollutant explanation coming soon.',
              ),

              const SizedBox(height: 24),

              // ── DAQI band scale ───────────────────────────────────────────
              const _SectionHeader(title: 'Air quality scale'),
              const SizedBox(height: 8),
              const _PlaceholderText(
                // TODO: Build the DAQI band scale visual with current reading marked
                text: 'DAQI band scale coming soon.',
              ),

              const SizedBox(height: 24),

              // ── Health recommendation ─────────────────────────────────────
              const _SectionHeader(title: 'Health recommendation'),
              const SizedBox(height: 8),
              const _PlaceholderText(
                // TODO: Fill in health recommendation for the current DAQI band
                text: 'Health recommendation coming soon.',
              ),

              const SizedBox(height: 24),

              // ── Customise threshold button ────────────────────────────────
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to threshold customisation in Profile → Alerts
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: const Text('Customise threshold'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColours.accent,
                  side: BorderSide(color: AppColours.accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColours.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _PlaceholderText extends StatelessWidget {
  final String text;
  const _PlaceholderText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColours.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColours.textSecondary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColours.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}