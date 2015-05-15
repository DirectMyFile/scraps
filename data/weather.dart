import "platform.dart";

class WeatherLocation {
  final String city;
  final String country;
  final String region;

  WeatherLocation(this.city, this.country, this.region);
}

class WeatherUnits {
  final String distance;
  final String pressure;
  final String speed;
  final String temperature;

  WeatherUnits(this.distance, this.pressure, this.speed, this.temperature);
}

class WeatherWind {
  final String chill;
  final String direction;
  final String text;

  WeatherWind(this.chill, this.direction, this.text);
}

class Weather {
  String title;
  String link;
  String description;
  String language;
  String ttl;
  WeatherLocation location;
  WeatherUnits units;
  WeatherWind wind;

  Weather();

  factory Weather.fromJSON(json) {
    var w = new Weather();
    w.title = json["title"];
    w.link = json["link"];
    w.description = json["description"];
    w.language = json["language"];
    w.ttl = json["ttl"];
    var l = json["location"];
    w.location = new WeatherLocation(l["city"], l["country"], l["region"]);
    var u = json["units"];
    w.units = new WeatherUnits(u["distance"], u["pressure"], u["speed"], u["temperature"]);
    return w;
  }
}

class WeatherClient {
  static const String urlBase = "https://query.yahooapis.com/v1/public/yql";

  final PlatformAdapter adapter;

  WeatherClient(this.adapter);

  void getWeatherByCity(String city, void handler(Weather weather)) {
    var url = _generateUrl(_buildCityQuery(city));
    adapter.fetchString("GET", url, (code, content, headers) {
      var json = adapter.parseJSON(content);
      var weather = new Weather.fromJSON(json["query"]["results"]["channel"]);
      handler(weather);
    });
  }

  String _buildCityQuery(String city) {
    return 'select * from weather.forecast where woeid in (select woeid from geo.places(1) where text="${city}")';
  }

  String _generateUrl(String yql) {
    yql = adapter.encodeUriComponent(yql);

    return "${urlBase}?q=${yql}&format=json&env=${adapter.encodeUriComponent("store://datatables.org/alltableswithkeys")}";
  }
}
