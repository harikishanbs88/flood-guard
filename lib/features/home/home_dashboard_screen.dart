import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/risk_level_helper.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/flood_risk_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/jal_kavach_logo.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/status_banner.dart';

class HomeDashboardScreen extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const HomeDashboardScreen({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData({bool force = false}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final locId = appState.selectedLocationId;
    Provider.of<WeatherProvider>(context, listen: false)
        .loadWeather(locId, forceRefresh: force);
    Provider.of<FloodRiskProvider>(context, listen: false)
        .loadFloodRisk(locId, forceRefresh: force);
    Provider.of<AlertsProvider>(context, listen: false)
        .loadAlerts(locationId: locId, forceRefresh: force);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final weatherProv = context.watch<WeatherProvider>();
    final floodProv = context.watch<FloodRiskProvider>();
    final alertsProv = context.watch<AlertsProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context, appState),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _loadData(force: true);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Status Banner (Demo or Offline Mode)
            if (appState.isOffline)
              StatusBanner.offlineNotice(onRetry: () => _loadData(force: true))
            else
              StatusBanner.demoNotice(),

            const SizedBox(height: 12),

            // 1. Emergency Alert Summary Banner (if active severe alerts)
            _buildActiveAlertBanner(context, alertsProv),

            const SizedBox(height: 14),

            // 2. Current Flood Risk Level Card
            _buildFloodRiskCard(context, floodProv),

            const SizedBox(height: 16),

            // 3. Current Weather Overview
            _buildWeatherSummaryCard(context, weatherProv),

            const SizedBox(height: 20),

            // 4. Quick Action Grid (6 key modules)
            _buildQuickActionsGrid(context),

            const SizedBox(height: 20),

            // 5. River Water Level Quick Gauge (CWC Telemetry)
            if (floodProv.floodRisk?.riverGauge != null)
              _buildRiverLevelCard(context, floodProv),

            const SizedBox(height: 20),

            // 6. Latest Verified Updates & Advisories
            _buildLatestUpdatesSection(context, alertsProv),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppStateProvider appState) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const JalKavachLogo(size: 24),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              InkWell(
                onTap: () => _showLocationSelectorDialog(context, appState),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      appState.selectedLocation['name'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Offline / Live Toggle simulation chip
        IconButton(
          tooltip: 'Toggle Offline / Online Simulation',
          icon: Icon(
            appState.isOffline
                ? Icons.wifi_off_rounded
                : Icons.wifi_rounded,
            color: appState.isOffline ? AppColors.error : AppColors.success,
            size: 22,
          ),
          onPressed: () {
            appState.toggleOfflineMode();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  appState.isOffline
                      ? 'Switched to Offline Mode (Cached Telemetry)'
                      : 'Switched to Online Mode',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        // Alert Bell with Badge
        Consumer<AlertsProvider>(
          builder: (context, alerts, _) {
            final severeCount = alerts.severeAlertsCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    widget.onNavigateToTab(3); // Go to Alerts tab
                  },
                ),
                if (severeCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.riskSevere,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$severeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildActiveAlertBanner(
      BuildContext context, AlertsProvider alertsProv) {
    if (alertsProv.isLoading) {
      return const SizedBox.shrink();
    }

    final severeAlerts = alertsProv.allAlerts
        .where((a) => a.severity == RiskLevel.severe)
        .toList();

    if (severeAlerts.isEmpty) return const SizedBox.shrink();

    final topAlert = severeAlerts.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onNavigateToTab(3), // Navigate to Alerts
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha(80),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SEVERE ALERT',
                              style: TextStyle(
                                color: Color(0xFFB71C1C),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topAlert.affectedLocation,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topAlert.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloodRiskCard(
      BuildContext context, FloodRiskProvider floodProv) {
    if (floodProv.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: CustomCard(
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final risk = floodProv.floodRisk;
    final riskLevel = risk?.riskLevel ?? RiskLevel.moderate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomCard(
        onTap: () {
          widget.onNavigateToTab(4); // Navigate to dedicated Flood Risk screen
        },
        borderColor: riskLevel.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tsunami_rounded,
                        color: riskLevel.color, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'ESTIMATED FLOOD RISK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                RiskBadge(riskLevel: riskLevel, isCompact: true),
              ],
            ),
            const SizedBox(height: 14),

            // Visual Progress Meter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      riskLevel.label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: riskLevel.color,
                      ),
                    ),
                    Text(
                      'Risk Score: ${risk?.riskScore ?? 65}/100',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (risk?.riskScore ?? 65) / 100.0,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(riskLevel.color),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Short explanation
            Text(
              risk?.riskExplanation ??
                  'Hydrological analysis shows heightened catchment runoff.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Source: CWC & AI Ensemble',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'View In-Depth Analysis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSummaryCard(
      BuildContext context, WeatherProvider weatherProv) {
    if (weatherProv.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: CustomCard(
          child: SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final weather = weatherProv.weather;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomCard(
        onTap: () {
          widget.onNavigateToTab(1); // Navigate to Weather tab
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.cloud_queue_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather?.temperature.toStringAsFixed(1) ?? '27.5'}°C',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          weather?.condition ?? 'Monsoon Rain',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => widget.onNavigateToTab(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F4F8),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '7-Day Forecast',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // 4 Weather Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMetricItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Rainfall Rate',
                  value: '${weather?.rainfallRate ?? 14.8} mm/h',
                  color: AppColors.secondary,
                ),
                _buildWeatherMetricItem(
                  icon: Icons.opacity_rounded,
                  label: 'Humidity',
                  value: '${weather?.humidity ?? 88}%',
                  color: Colors.teal,
                ),
                _buildWeatherMetricItem(
                  icon: Icons.air_rounded,
                  label: 'Wind Speed',
                  value: '${weather?.windSpeed ?? 24.5} km/h',
                  color: Colors.blueGrey,
                ),
                _buildWeatherMetricItem(
                  icon: Icons.umbrella_rounded,
                  label: '24h Total',
                  value: '${weather?.rainfallLast24h ?? 112.4} mm',
                  color: Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMERGENCY & PREPAREDNESS MODULES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              _buildQuickActionTile(
                title: 'Hazard Map',
                subtitle: 'India Geospatial',
                icon: Icons.map_rounded,
                color: const Color(0xFF0288D1),
                onTap: () => widget.onNavigateToTab(2), // Hazard Map
              ),
              _buildQuickActionTile(
                title: 'Flood Risk',
                subtitle: 'CWC Telemetry',
                icon: Icons.tsunami_rounded,
                color: const Color(0xFF1976D2),
                onTap: () => widget.onNavigateToTab(4), // Flood Risk
              ),
              _buildQuickActionTile(
                title: 'Active Alerts',
                subtitle: 'NDMA Warns',
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFFD32F2F),
                onTap: () => widget.onNavigateToTab(3), // Alerts
              ),
              _buildQuickActionTile(
                title: 'Multi-Disaster',
                subtitle: '9 Hazard Monitor',
                icon: Icons.warning_rounded,
                color: const Color(0xFFF57C00),
                onTap: () => widget.onNavigateToTab(5), // Disasters
              ),
              _buildQuickActionTile(
                title: 'Safety Guide',
                subtitle: 'Prep Checklist',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF388E3C),
                onTap: () => widget.onNavigateToTab(6), // Safety
              ),
              _buildQuickActionTile(
                title: 'Emergency',
                subtitle: 'Quick Call 112',
                icon: Icons.emergency_rounded,
                color: const Color(0xFFC2185B),
                onTap: () => widget.onNavigateToTab(7), // Emergency Contacts
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiverLevelCard(
      BuildContext context, FloodRiskProvider floodProv) {
    final gauge = floodProv.floodRisk!.riverGauge!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomCard(
        onTap: () => widget.onNavigateToTab(4), // Go to Flood Risk
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      gauge.riverName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                            ? Icons.trending_up_rounded
                            : Icons.trending_flat_rounded,
                        size: 14,
                        color: gauge.trend == 'RISING'
                            ? AppColors.riskSevere
                            : AppColors.riskLow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gauge.trend,
                        style: TextStyle(
                          fontSize: 10,
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
            const SizedBox(height: 6),
            Text(
              'Station: ${gauge.stationName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Water Level Comparative Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Level',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${gauge.currentLevelMeters.toStringAsFixed(2)} m',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Warning Mark',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gauge.warningLevelMeters.toStringAsFixed(2)} m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.riskModerate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.divider,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danger Mark',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${gauge.dangerLevelMeters.toStringAsFixed(2)} m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.riskSevere,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestUpdatesSection(
      BuildContext context, AlertsProvider alertsProv) {
    final alerts = alertsProv.allAlerts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LATEST VERIFIED BULLETINS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab(3),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('View All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            const CustomCard(
              child: Text('No active advisories reported for this region.'),
            )
          else
            ...alerts.map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomCard(
                  onTap: () => widget.onNavigateToTab(3),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: alert.severity.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          alert.severity.icon,
                          size: 18,
                          color: alert.severity.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormatter.timeAgo(alert.issuedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (alert.isOfficialGovernmentWarning)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'OFFICIAL GOVT',
                                      style: TextStyle(
                                        color: AppColors.riskLow,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE7F6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'AI ESTIMATE',
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Source: ${alert.source}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showLocationSelectorDialog(
      BuildContext context, AppStateProvider appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select River Basin / Region',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: appState.allLocations.length,
                  itemBuilder: (ctx, i) {
                    final loc = appState.allLocations[i];
                    final isSelected = loc['id'] == appState.selectedLocationId;

                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.location_city_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        loc['name'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${loc['state']} • ${loc['basin']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: loc['highRisk'] == true
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.riskSevereBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Flood Prone',
                                style: TextStyle(
                                  color: AppColors.riskSevere,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        appState.changeLocation(loc['id']);
                        _loadData(force: true);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

