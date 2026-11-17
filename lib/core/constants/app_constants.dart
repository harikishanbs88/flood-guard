class AppConstants {
  static const String appName = 'JalKavach';
  static const String appFullName = 'JalKavach - Flood Preparedness & Emergency Alerts';
  static const String appTagline = 'A strong Indian identity.';
  static const String appVersion = '1.0.0';

  // API Backend default configuration (FastAPI)
  static const String defaultApiBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String productionApiBaseUrl = 'https://api.jalrakshak.gov.in/api/v1';

  // Supported Monitoring Regions (India River Basins & Flood Hotspots)
  static const List<Map<String, dynamic>> predefinedLocations = [
    {
      'id': 'patna_bihar',
      'name': 'Patna, Bihar',
      'state': 'Bihar',
      'basin': 'Ganga River Basin',
      'latitude': 25.5941,
      'longitude': 85.1376,
      'isDefault': true,
      'highRisk': true,
    },
    {
      'id': 'guwahati_assam',
      'name': 'Guwahati, Assam',
      'state': 'Assam',
      'basin': 'Brahmaputra Basin',
      'latitude': 26.1445,
      'longitude': 91.7362,
      'isDefault': false,
      'highRisk': true,
    },
    {
      'id': 'cuttack_odisha',
      'name': 'Cuttack, Odisha',
      'state': 'Odisha',
      'basin': 'Mahanadi Basin',
      'latitude': 20.4625,
      'longitude': 85.8828,
      'isDefault': false,
      'highRisk': true,
    },
    {
      'id': 'srinagar_jk',
      'name': 'Srinagar, J&K',
      'state': 'Jammu & Kashmir',
      'basin': 'Jhelum Basin',
      'latitude': 34.0837,
      'longitude': 74.7973,
      'isDefault': false,
      'highRisk': false,
    },
    {
      'id': 'vijayawada_ap',
      'name': 'Vijayawada, AP',
      'state': 'Andhra Pradesh',
      'basin': 'Krishna Basin',
      'latitude': 16.5062,
      'longitude': 80.6480,
      'isDefault': false,
      'highRisk': false,
    },
    {
      'id': 'chennai_tn',
      'name': 'Chennai, Tamil Nadu',
      'state': 'Tamil Nadu',
      'basin': 'Adyar & Cooum Coastal Basin',
      'latitude': 13.0827,
      'longitude': 80.2707,
      'isDefault': false,
      'highRisk': false,
    },
    {
      'id': 'mumbai_mh',
      'name': 'Mumbai, Maharashtra',
      'state': 'Maharashtra',
      'basin': 'Mithi River Coastal Basin',
      'latitude': 19.0760,
      'longitude': 72.8777,
      'isDefault': false,
      'highRisk': false,
    },
    {
      'id': 'bengaluru_ka',
      'name': 'Bengaluru, Karnataka',
      'state': 'Karnataka',
      'basin': 'Vrishabhavathi & South Pennar',
      'latitude': 12.9716,
      'longitude': 77.5946,
      'isDefault': false,
      'highRisk': false,
    },
  ];

  // Official Emergency Helpline Numbers for India
  static const String helplineNDRF = '011-24363260';
  static const String helplineNDRFTollFree = '1078';
  static const String helplineNationalEmergency = '112';
  static const String helplineDisasterState = '1070';
  static const String helplineDisasterDistrict = '1077';
  static const String helplinePolice = '100';
  static const String helplineAmbulance = '108';
  static const String helplineFire = '101';
  static const String helplineWomen = '1091';

  // Demo Notice Disclaimer
  static const String demoDataNotice =
      'DEMONSTRATION MODE: Data is simulated for architecture evaluation. Connect to FastAPI backend for live IMD & CWC telemetry.';
}

