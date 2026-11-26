import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_dashboard/routes/app_routes.dart';
import 'package:smart_dashboard/screens/shared/add_location_screen.dart';
import 'package:smart_dashboard/widgets/network_status.dart';

import 'test_helpers.dart';

/// A real JPEG to stand in for a photo from the camera or library.
File _samplePhoto() {
  final dir = Directory.systemTemp.createTempSync('scg_photo');
  return File('assets/images/locations/library.jpg')
      .copySync('${dir.path}/picked.jpg');
}

void main() {
  late File photo;

  setUp(() {
    photo = _samplePhoto();
    AddLocationScreen.pickPhoto = ({required bool camera}) async => photo;
  });

  testWidgets('A student adds a location with a photo while offline', (
    tester,
  ) async {
    final services = await tester.runAsync(() => makeServices(online: false));
    await pumpApp(tester, services: services);
    await signInAs(tester, 'student', 'student123');
    await pushRoute(tester, AppRoutes.campusTour);

    await tester.ensureVisible(find.byKey(const Key('tour.addLocation')));
    await tester.tap(find.byKey(const Key('tour.addLocation')));
    await tester.pumpAndSettle();
    expect(find.text('Add Location'), findsWidgets);

    // Saving empty shows every required message, including the photo.
    await tester.tap(find.byKey(const Key('location.save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the location name.'), findsOneWidget);
    expect(find.text('Enter the description.'), findsOneWidget);
    expect(find.text('Add a photo of the location.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('location.photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from Library'));
    await tester.pumpAndSettle();
    expect(find.text('Change photo'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('location.title')), 'Chapel');
    await tester.enterText(
      find.byKey(const Key('location.subtitle')),
      'Place of worship',
    );
    await tester.enterText(
      find.byKey(const Key('location.description')),
      'Quiet chapel open to students and staff.',
    );
    await tester.ensureVisible(find.byKey(const Key('location.save')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('location.save')));
      // Let the photo copy finish on the real file system.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Saved on the phone, pending upload, and listed in the tour.
    final tour = services!.tour;
    expect(tour.addedLocations, hasLength(1));
    final added = tour.addedLocations.single;
    expect(added.title, 'Chapel');
    expect(added.synced, isFalse);
    expect(added.photoFile, isNotNull);
    expect(File(added.photoFile!).existsSync(), isTrue);
    expect(tour.pendingLocationCount, 1);
    expect(services.sync.state, NetworkState.offline);
    expect(find.text('Chapel'), findsOneWidget);
    expect(find.text('Place of worship · Pending upload'), findsOneWidget);

    // Back online: it uploads with the rest of the queue.
    await tester.runAsync(() => services.sync.setOnline(true));
    await tester.pumpAndSettle();
    expect(tour.addedLocations.single.synced, isTrue);
    expect(tour.pendingCount, 0);
    expect(find.text('Place of worship · Added'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  test('Added locations survive a restart and can be deleted', () async {
    final services = await makeServices();
    final tour = services.tour;
    final added = await tour.addLocation(
      title: 'Chapel',
      description: 'Quiet chapel.',
      photo: photo,
    );
    expect(tour.locations, hasLength(7));
    expect(tour.byId(added.id)?.title, 'Chapel');
    // Tour progress still counts the six built-in locations.
    expect(tour.visitedCount, 0);
    await tour.recordVisit(added.id);
    expect(tour.visitedCount, 0);

    tour.load();
    expect(tour.addedLocations.single.title, 'Chapel');

    await tour.deleteLocation(added.id);
    expect(tour.locations, hasLength(6));
    expect(tour.visitsFor(added.id), isEmpty);
    expect(File(added.photoFile!).existsSync(), isFalse);
  });

  testWidgets('Analytics shows a Network Status card', (tester) async {
    await pumpApp(tester);
    await signInAs(tester, 'faculty', 'faculty123');
    await tapNav(tester, 'Analytics');
    await tester.scrollUntilVisible(
      find.text('Network Status'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Network Status'), findsOneWidget);
    expect(find.text('ONLINE'), findsWidgets);
  });
}
