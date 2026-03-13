# Breakdown Location Picker — Integration Guide

## Files added

| File | Purpose |
|------|---------|
| `lib/screens/breakdown/breakdown_location_picker_screen.dart` | Map picker screen |
| `lib/screens/breakdown/breakdown_example_usage.dart` | Usage patterns + demo widget |
| `lib/models/breakdown_request.dart` | Data model |

## Package additions (pubspec.yaml)

```yaml
flutter_map: ^7.0.2   # OpenStreetMap renderer
latlong2: ^0.9.1      # LatLng coordinate type
# geolocator already existed
```

## Android permissions (already present in AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## go_router route (added to main.dart)

```dart
GoRoute(
  path: '/breakdown-location',
  builder: (_, state) {
    final issue = state.extra as String? ?? '';
    return BreakdownLocationPickerScreen(initialIssue: issue);
  },
),
```

---

## Usage — Pattern A (recommended, returns result directly)

```dart
import 'package:raahi/screens/breakdown/breakdown_example_usage.dart';
import 'package:raahi/models/breakdown_request.dart';

// Inside any async function / button handler:
final BreakdownRequest? request = await openBreakdownPicker(
  context,
  initialIssue: 'Tyre puncture on NH-44',   // optional
);

if (request != null) {
  print('Lat: ${request.latitude}');
  print('Lng: ${request.longitude}');

  // Send to backend
  await ApiService().createBreakdownRequest(request.toJson());
}
```

Returned JSON shape:
```json
{
  "latitude": 28.6139,
  "longitude": 77.2090,
  "issue_description": "Tyre puncture on NH-44",
  "timestamp": "2025-03-11T09:41:00.000"
}
```

---

## Usage — Pattern B (go_router, no return value)

```dart
// Push to picker (issue description passed as extra)
context.push('/breakdown-location', extra: 'Engine overheating');
```

> For return data with go_router, use a Riverpod `StateProvider<BreakdownRequest?>` 
> that the picker writes to before popping.

---

## How the map works

- On load → `Geolocator.getCurrentPosition()` → map centers on GPS
- Centered **car_repair** pin is fixed to screen; map moves beneath it  
- On `MapEventMoveEnd` → `_center` updates to `mapController.camera.center`
- Confirm → creates `BreakdownRequest` → `Navigator.pop(context, request)`
- Tiles from: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- Dark tint applied via `ColorFiltered` matrix to match app theme

---

## Adding reverse geocoding (optional)

The screen currently shows raw coordinates. To show a street address:

```dart
// pubspec.yaml — already present:
//   geocoding: ^3.0.0

import 'package:geocoding/geocoding.dart';

Future<void> _updateAddressLabel(LatLng ll) async {
  try {
    final placemarks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
    if (placemarks.isNotEmpty && mounted) {
      final p = placemarks.first;
      setState(() {
        _addressLabel = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
      });
    }
  } catch (_) {
    _updateAddressLabel(ll); // fallback to coordinates
  }
}
```
