import "dart:html";
import "package:google_maps/google_maps.dart";

main() async {
  var map = new GMap(querySelector("#map"), new MapOptions()
    ..center = new LatLng(0, 0)
    ..mapTypeId = MapTypeId.ROADMAP
    ..zoom = 17
  );

  Marker marker = new Marker();
  marker.map = map;
  marker.title = "Your Location";
  marker.clickable = true;
  marker.visible = false;

  var stream = window.navigator.geolocation.watchPosition(
    enableHighAccuracy: true,
    timeout: new Duration(seconds: 10),
    maximumAge: new Duration(seconds: 30)
  );

  try {
    await for (Geoposition location in stream) {
      var coords = location.coords;
      map.center = new LatLng(coords.latitude, coords.longitude);
      map.heading = coords.heading;
      marker.position = new LatLng(coords.latitude, coords.longitude);
      marker.visible = true;
    }
  } on PositionError catch (e) {
    window.alert(e.message);
  }
}
