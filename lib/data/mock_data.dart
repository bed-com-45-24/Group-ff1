import '../models/route.dart';

final List<MovaRoute> mockRoutes = [
  MovaRoute(
    id: '1',
    name: 'Limbe - Chichiri',
    fare: 1500,
    duration: '25 min',
    stops: ['Limbe Depot', 'Ndirande Turn', 'Chichiri Mall'],
  ),
  MovaRoute(
    id: '2',
    name: 'Blantyre CBD - Ndirande',
    fare: 1200,
    duration: '20 min',
    stops: ['Blantyre Market', 'Mbayani', 'Ndirande Main'],
  ),
  MovaRoute(
    id: '3',
    name: 'Chilomoni - Chichiri',
    fare: 1000,
    duration: '15 min',
    stops: ['Chilomoni Market', 'Green Corner', 'Chichiri'],
  ),
];