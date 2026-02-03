import 'package:http/http.dart' as http;

class MapService {
  final String provinceUrl =
      'https://raw.githubusercontent.com/Acesmndr/nepal-geojson/master/generated-geojson/nepal-with-provinces-acesmndr.geojson';
  final String districtUrl =
      'https://raw.githubusercontent.com/Acesmndr/nepal-geojson/master/generated-geojson/nepal-with-districts-acesmndr.geojson';
  final String palikaUrl =
      'https://raw.githubusercontent.com/younginnovations/nepal-locallevel-map/master/out/municipalities.simplified.geojson';

  Future<Map<String, String>> fetchGeoJsonData() async {
    final results = await Future.wait([
      http.get(Uri.parse(provinceUrl)),
      http.get(Uri.parse(districtUrl)),
      http.get(Uri.parse(palikaUrl)),
    ]);

    final Map<String, String> data = {};
    if (results[0].statusCode == 200) data['provinces'] = results[0].body;
    if (results[1].statusCode == 200) data['districts'] = results[1].body;
    if (results[2].statusCode == 200) data['palikas'] = results[2].body;

    return data;
  }
}
