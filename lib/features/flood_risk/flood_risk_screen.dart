import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/risk_level_helper.dart';
import '../../models/flood_risk_model.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/flood_risk_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/risk_badge.dart';

class FloodRiskScreen extends StatelessWidget {
  const FloodRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final floodProv = context.watch<FloodRiskProvider>();
    final risk = floodProv.floodRisk;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hydrological Flood Risk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${appState.selectedLocation['name']} • River Basin Telemetry',
              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              floodProv.loadFloodRisk(
                appState.selectedLocationId,
                forceRefresh: true,
              );
            },
          ),
        ],
      ),
      body: floodProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await floodProv.loadFloodRisk(
                  appState.selectedLocationId,
                  forceRefresh: true,
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Prominent Flood Risk Severity Gauge Card
                  _buildRiskGaugeCard(risk),

                  const SizedBox(height: 16),

                  // 2. River Level CWC Gauge Card (Current vs Warning vs Danger)
                  if (risk?.riverGauge != null)
                    _buildRiverGaugeCard(risk!.riverGauge!),

                  const SizedBox(height: 16),

                  // 3. Catchment Runoff & Rainfall Dynamics
                  _buildHydrologicalFactorsCard(risk),

                  const SizedBox(height: 16),

                  // 4. ML Prediction Uncertainty & Confidence Intervals Card
                  _buildPredictionUncertaintyCard(risk),
                ],
              ),
            ),
    );
  }

  Widget _buildRiskGaugeCard(FloodRiskModel? risk) {
    final level = risk?.riskLevel ?? RiskLevel.moderate;
    final score = risk?.riskScore ?? 65;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: level.color.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                risk?.riverBasin.toUpperCase() ?? 'GANGA BASIN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              RiskBadge(riskLevel: level),
            ],
          ),
          const SizedBox(height: 16),

          // Circular Score Dial & Label
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score / 100.0,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(level.color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: level.color,
                      ),
                    ),
                    const Text(
                      'RISK INDEX / 100',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            level.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: level.color,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            level.advisory,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 14),

          // Detailed Hydrological Explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: level.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: level.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.analytics_outlined, size: 18, color: level.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    risk?.riskExplanation ?? 'Hydrological conditions indicate elevated runoff into the main river channel.',
                    style: TextStyle(
                      fontSize: 12,
                      color: level.color,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiverGaugeCard(RiverGaugeData gauge) {
    // Percentage towards danger mark
    final double range = gauge.dangerLevelMeters - gauge.warningLevelMeters;
    final double progress = range > 0
        ? ((gauge.currentLevelMeters - gauge.warningLevelMeters) / range).clamp(
            0.0,
            1.2,
          )
        : 0.5;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.waves_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gauge.riverName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gauge.trend == 'RISING'
                      ? AppColors.riskSevereBg
                      : AppColors.riskLowBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      gauge.trend == 'RISING'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: gauge.trend == 'RISING'
                          ? AppColors.riskSevere
                          : AppColors.riskLow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${gauge.trend} (+3.5 cm/h)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: gauge.trend == 'RISING'
                            ? AppColors.riskSevere
                            : AppColors.riskLow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Central Water Commission (CWC) • ${gauge.stationName}',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Visual Level Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hydrological Gauge Reading',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${gauge.currentLevelMeters.toStringAsFixed(2)} m',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    gauge.isAboveDangerLevel
                        ? AppColors.riskSevere
                        : gauge.isAboveWarningLevel
                        ? AppColors.riskHigh
                        : AppColors.riskModerate,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Warning: ${gauge.warningLevelMeters.toStringAsFixed(2)}m',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.riskModerate,
                    ),
                  ),
                  Text(
                    'Danger: ${gauge.dangerLevelMeters.toStringAsFixed(2)}m',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.riskSevere,
                    ),
                  ),
                  Text(
                    'HFL: ${gauge.highestFloodLevelMeters.toStringAsFixed(2)}m',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrologicalFactorsCard(FloodRiskModel? risk) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RUNOFF & CATCHMENT PARAMETERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildParameterBox(
                  icon: Icons.water_drop_rounded,
                  label: '24h Observed Rain',
                  value:
                      '${risk?.rainfall24hMm.toStringAsFixed(1) ?? '112.4'} mm',
                  subtitle: 'Heavy downpour',
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildParameterBox(
                  icon: Icons.cloud_sync_rounded,
                  label: '48h Forecast Rain',
                  value:
                      '${risk?.rainfall48hPredictedMm.toStringAsFixed(1) ?? '145.0'} mm',
                  subtitle: 'IMD Ensemble',
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildParameterBox(
                  icon: Icons.grass_rounded,
                  label: 'Soil Saturation',
                  value:
                      '${risk?.soilSaturationPercent.toStringAsFixed(1) ?? '91.5'}%',
                  subtitle: 'Low absorption capacity',
                  color: Colors.brown,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildParameterBox(
                  icon: Icons.timer_outlined,
                  label: 'Peak Crest Inflow',
                  value: '14 - 18 hrs',
                  subtitle: 'Upstream confluence',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterBox({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionUncertaintyCard(FloodRiskModel? risk) {
    final uncertainty =
        risk?.uncertainty ?? PredictionUncertainty.defaultModel();
    final confidencePercent = (uncertainty.confidenceScore * 100).toInt();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI MODEL UNCERTAINTY & CONFIDENCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$confidencePercent% Confidence',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Architecture: ${uncertainty.modelName}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            uncertainty.uncertaintyDescription,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Visual Uncertainty Range Chart (fl_chart)
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 40,
                maxY: 100,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        switch (val.toInt()) {
                          case 0:
                            return const Text(
                              '6h',
                              style: TextStyle(fontSize: 10),
                            );
                          case 1:
                            return const Text(
                              '12h',
                              style: TextStyle(fontSize: 10),
                            );
                          case 2:
                            return const Text(
                              '24h',
                              style: TextStyle(fontSize: 10),
                            );
                          case 3:
                            return const Text(
                              '36h',
                              style: TextStyle(fontSize: 10),
                            );
                          case 4:
                            return const Text(
                              '48h',
                              style: TextStyle(fontSize: 10),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, _) {
                        if (val % 20 == 0) {
                          return Text(
                            '${val.toInt()}',
                            style: const TextStyle(fontSize: 9),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Expected Risk Projection
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    spots: const [
                      FlSpot(0, 65),
                      FlSpot(1, 72),
                      FlSpot(2, 78),
                      FlSpot(3, 75),
                      FlSpot(4, 60),
                    ],
                  ),
                  // Upper Bound Confidence Margin
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.riskSevere.withAlpha(120),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    spots: const [
                      FlSpot(0, 72),
                      FlSpot(1, 80),
                      FlSpot(2, 86),
                      FlSpot(3, 83),
                      FlSpot(4, 68),
                    ],
                  ),
                  // Lower Bound Confidence Margin
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.riskLow.withAlpha(120),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    spots: const [
                      FlSpot(0, 58),
                      FlSpot(1, 64),
                      FlSpot(2, 71),
                      FlSpot(3, 67),
                      FlSpot(4, 52),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppColors.primary, 'Expected Risk'),
              const SizedBox(width: 12),
              _buildLegendDot(
                AppColors.riskSevere.withAlpha(150),
                'Upper Margin',
              ),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.riskLow.withAlpha(150), 'Lower Margin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
