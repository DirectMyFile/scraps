import "package:redstone_mapper/mapper.dart";
import "package:redstone_mapper/mapper_factory.dart";

import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

http.Client client = new http.Client();

const String BASE_URL = "https://maps.googleapis.com/maps/api/directions/json";

Future<dynamic> getJSON(String url, {Map<String, dynamic> params: const {}, Type type}) async {
  var qs = "";
  if (params.isNotEmpty) {
    qs += "?";
    var first = true;
    for (var key in params.keys) {
      if (first) {
        first = false;
      } else {
        qs += "&";
      }
      qs += "${key}=${Uri.encodeComponent(params[key].toString())}";
    }
  }
  var response = await client.get(url + qs);
  if (type != null) {
    return decodeJson(response.body, type);
  } else {
    return JSON.decode(response.body);
  }
}

class DirectionsMode {
  static const DirectionsMode DRIVING = const DirectionsMode("driving");
  static const DirectionsMode TRANSIT = const DirectionsMode("transit");

  final String name;

  const DirectionsMode(this.name);
}

class TransitMode {
  static const TransitMode BUS = const TransitMode("bus");
  static const TransitMode SUBWAY = const TransitMode("subway");
  static const TransitMode TRAIN = const TransitMode("train");
  static const TransitMode TRAM = const TransitMode("tram");
  static const TransitMode RAIL = const TransitMode("rail");

  final String name;

  const TransitMode(this.name);

  TransitMode operator |(TransitMode other) {
    return new TransitMode( "${this.name}|${other.name}");
  }
}

Future<Directions> getDirections(origin, destination, {
  mode: DirectionsMode.DRIVING,
  String key,
  List<dynamic> waypoints,
  bool alternatives,
  TransitMode transitMode,
  arrivalTime,
  departureTime
  }) {
  bootstrapMapper();

  if (origin is Location) {
    origin = "${origin.latitude}${origin.longitude}";
  }

  if (destination is Location) {
    destination = "${destination.latitude}${destination.longitude}";
  }

  if (arrivalTime is DateTime) {
    arrivalTime = arrivalTime.millisecondsSinceEpoch;
  }

  if (departureTime is DateTime) {
    departureTime = departureTime.millisecondsSinceEpoch;
  }

  var map = {
    "origin": origin,
    "destination": destination,
    "mode": mode.name
  };

  if (transitMode != null) {
    map["transit_mode"] = transitMode.name;
  }

  if (arrivalTime != null) {
    map["arrival_time"] = arrivalTime;
  }

  if (departureTime != null) {
    map["departure_time"] = departureTime;
  }

  if (waypoints != null) {
    map["waypoints"] = waypoints.map((it) {
      if (it is Location) {
        return "${it.latitude}${it.longitude}";
      } else {
        return it.toString();
      }
    }).join("|");
  }

  if (alternatives) {
    map["alternatives"] = alternatives;
  }

  if (key != null) {
    map["key"] = key;
  }

  return getJSON(BASE_URL, params: map, type: Directions);
}

class Directions {
  @Field()
  List<Route> routes;
}

class Route {
  @Field()
  List<Leg> legs;

  @Field()
  RouteBounds bounds;

  @Field()
  Fare fare;
}

class DirectionsTime {
  @Field()
  int value;

  @Field()
  String text;

  @Field(model: "time_zone")
  String timezone;
}

class RouteBounds {
  @Field()
  Location northeast;
  @Field()
  Location southwest;
}

class Leg {
  @Field()
  LegDistance distance;

  @Field()
  LegDuration duration;

  @Field(model: "end_address")
  String endAddress;

  @Field(model: "end_location")
  Location endLocation;

  @Field(model: "start_address")
  String startAddress;

  @Field(model: "start_location")
  Location startLocation;

  @Field()
  List<Step> steps;
}

class LegDistance {
  @Field()
  String text;

  @Field()
  int value;
}

class LegDuration {
  @Field()
  String text;

  @Field()
  int value;
}

class Step {
  @Field()
  LegDistance distance;

  @Field()
  LegDuration duration;

  @Field()
  Location startLocation;

  @Field()
  String maneuver;

  @Field(model: "html_instructions")
  String htmlInstructions;

  @Field(model: "travel_mode")
  String travelMode;

  @Field(model: "end_location")
  Location endLocation;
}

class Location {
  @Field()
  double latitude;

  @Field()
  double longitude;
}

class Fare {
  @Field()
  String currency;

  @Field()
  int value;
}

main() async {
  Directions dir = await getDirections(
      "Salem, AL",
      "San Francisco, CA",
      key: "AIzaSyC9dyRtyQr1QJZuYlN_2gFsHfRw7COza2s",
      mode: DirectionsMode.DRIVING
  );

  for (var route in dir.routes) {
    for (var leg in route.legs) {
      print("- Distance: ${leg.distance.text}");
      print("- Duration: ${leg.duration.text}");
      for (var step in leg.steps) {
        print("  - Distance: ${step.distance.text}");
        print("  - Duration: ${step.duration.text}");
        print("  - Maneuver: ${step.maneuver}");
      }
    }
  }

  client.close();
}
