
import '../models/route_model.dart';

// MOVA official routes - fares based on SOSOSO poster 03 April 2026 (used as reference data)
final List<RouteModel> sampleRoutes = [
  // FROM BLANTYRE
  RouteModel(id: 'MOVA-BT-NC-001', companyName: 'MOVA', name: 'Blantyre to Ntcheu', origin: 'Blantyre', destination: 'Ntcheu', stops: ['Blantyre Main Stage', 'Zalewa', 'Ntcheu'], fare: 60000, duration: '4h 30m', transfers: 0, departureTimes: ['06:00', '08:30']),
  RouteModel(id: 'MOVA-BT-LL-002', companyName: 'MOVA', name: 'Blantyre to Lilongwe', origin: 'Blantyre', destination: 'Lilongwe', stops: ['Blantyre', 'Ntcheu', 'Dedza', 'Lilongwe'], fare: 75000, duration: '5h', transfers: 0, departureTimes: ['05:30', '07:00', '14:00']),
  RouteModel(id: 'MOVA-BT-KS-003', companyName: 'MOVA', name: 'Blantyre to Kasungu', origin: 'Blantyre', destination: 'Kasungu', stops: ['Blantyre', 'Lilongwe', 'Kasungu'], fare: 120000, duration: '8h', transfers: 1, departureTimes: ['06:00']),
  RouteModel(id: 'MOVA-BT-JE-004', companyName: 'MOVA', name: 'Blantyre to Jenda', origin: 'Blantyre', destination: 'Jenda', stops: ['Blantyre', 'Lilongwe', 'Kasungu', 'Jenda'], fare: 130000, duration: '9h', transfers: 1, departureTimes: ['05:00']),
  RouteModel(id: 'MOVA-BT-MZ-005', companyName: 'MOVA', name: 'Blantyre to Mzimba/Mzuzu', origin: 'Blantyre', destination: 'Mzuzu', stops: ['Blantyre', 'Lilongwe', 'Mzuzu'], fare: 140000, duration: '10h', transfers: 1, departureTimes: ['04:30', '18:00']),

  // FROM LILONGWE
  RouteModel(id: 'MOVA-LL-NC-006', companyName: 'MOVA', name: 'Lilongwe to Ntcheu', origin: 'Lilongwe', destination: 'Ntcheu', stops: ['Lilongwe', 'Dedza', 'Ntcheu'], fare: 60000, duration: '2h', transfers: 0, departureTimes: ['07:00', '15:00']),
  RouteModel(id: 'MOVA-LL-BT-007', companyName: 'MOVA', name: 'Lilongwe to Blantyre', origin: 'Lilongwe', destination: 'Blantyre', stops: ['Lilongwe', 'Dedza', 'Ntcheu', 'Blantyre'], fare: 75000, duration: '5h', transfers: 0, departureTimes: ['06:00', '13:00']),
  RouteModel(id: 'MOVA-LL-KS-008', companyName: 'MOVA', name: 'Lilongwe to Kasungu', origin: 'Lilongwe', destination: 'Kasungu', stops: ['Lilongwe', 'Kasungu'], fare: 60000, duration: '1h 30m', transfers: 0, departureTimes: ['08:00', '10:00', '16:00']),
  RouteModel(id: 'MOVA-LL-MZ-009', companyName: 'MOVA', name: 'Lilongwe to Mzuzu', origin: 'Lilongwe', destination: 'Mzuzu', stops: ['Lilongwe', 'Kasungu', 'Jenda', 'Mzimba', 'Mzuzu'], fare: 85000, duration: '5h 30m', transfers: 0, departureTimes: ['06:30', '09:00']),
  RouteModel(id: 'MOVA-LL-KA-010', companyName: 'MOVA', name: 'Lilongwe to Karonga', origin: 'Lilongwe', destination: 'Karonga', stops: ['Lilongwe', 'Kasungu', 'Mzuzu', 'Karonga'], fare: 140000, duration: '9h', transfers: 1, departureTimes: ['05:30', '19:00']),

  // FROM MZUZU
  RouteModel(id: 'MOVA-MZ-MB-011', companyName: 'MOVA', name: 'Mzuzu to Mzimba', origin: 'Mzuzu', destination: 'Mzimba', stops: ['Mzuzu', 'Mzimba'], fare: 55000, duration: '45m', transfers: 0, departureTimes: ['07:00', '14:00']),
  RouteModel(id: 'MOVA-MZ-LL-012', companyName: 'MOVA', name: 'Mzuzu to Lilongwe', origin: 'Mzuzu', destination: 'Lilongwe', stops: ['Mzuzu', 'Mzimba', 'Kasungu', 'Lilongwe'], fare: 85000, duration: '5h 30m', transfers: 0, departureTimes: ['06:00', '13:30']),

  // FROM KARONGA
  RouteModel(id: 'MOVA-KA-UL-013', companyName: 'MOVA', name: 'Karonga to Uliwa', origin: 'Karonga', destination: 'Uliwa', stops: ['Karonga', 'Uliwa'], fare: 45000, duration: '1h', transfers: 0, departureTimes: ['08:00']),
  RouteModel(id: 'MOVA-KA-MZ-014', companyName: 'MOVA', name: 'Karonga to Mzuzu', origin: 'Karonga', destination: 'Mzuzu', stops: ['Karonga', 'Phwezi', 'Mzuzu'], fare: 70000, duration: '3h', transfers: 0, departureTimes: ['07:30']),
];