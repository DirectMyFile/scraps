import "weather.dart";
import "platform_io.dart";

main() {
  var client = new WeatherClient(new IOPlatformAdapter());
  client.getWeatherByCity("Salem Alabama", (Weather weather) {
    print(weather.title);
  });
}
