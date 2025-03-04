import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hyper_net/hyper_net.dart';
import 'package:hyper_net_example/model/Weather.dart';
import 'package:hyper_net_example/model/exception/custom_exception_message.dart';

import 'model/Cat.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//Base url that can be used for api client on whole app.
const String _baseUrl = 'https://api.open-meteo.com/v1/';
// weather endpoint
const String _forecastEndpoint = 'forecast';

//url to override the default base url with cats endpoint.
const String _catsUrl = 'https://api.thecatapi.com/v1/images/search';

class _MyHomePageState extends State<MyHomePage> {
  //Message for displaying current weather temperature from api.
  String _weatherMsg = '';

  //List of cats to be displayed from api.
  List<Cat> _cats = [];

  // determines whether the app is loading or not
  bool _isLoading = false;

  //you should create only one instance of this network client to be used for the app depending on your use case.
  late HyperNetClient _client;

  final settings = const HyperNetClientSettings(
    logSettings: HyperNetLoggerSettings(
      responseBody: true,
      request: true,
      attachLoggerOnDebug: true,
    ),
    //Whether you want to show api error message or default message.
    shouldShowApiErrors: true,
    //creates custom exception messages to be displayed when error is received.
    exceptionMessages: CustomExceptionMessage(),
    useIsolateForMappingJson: true,
    useWorkMangerForMappingJsonInIsolate: true,
  );

  @override
  void initState() {
    //Configure your network client based on your needs.

    _client = HyperNetClient(
        // customize your dio options.
        dio: Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
          ),
        ),
        //if you want to attach a token to the client.
        customHeaders: () => getCustomHeaders(),
        customQuery: () => {
              'locale': 'ar',
            },
        //attach logger to the client to print ongoing requests works only on debug mode.
        settings: settings,
        //converts json to error message.
        errorMapper: (json) {
          if (json.containsKey('message')) {
            return json['message'];
          }
          return null;
        },
        onUnauthorizedRequestReceived: (response) {
          final code = response?.statusCode;
          if (kDebugMode) {
            print('onUnauthorizedRequestReceived code :$code');
          }
        });
    super.initState();

    // Get weather and cats from api.
    getWeatherFromApi();
    getCatsFromApi();
  }

  Future<Map<String, dynamic>> getCustomHeaders() async {
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Hyper Network'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Current Weather is :',
                    ),
                  ),
                  Text(
                    _weatherMsg,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _cats.length,
                          itemBuilder: (context, index) {
                            return SizedBox(
                              height: 200,
                              child: Image.network(
                                _cats[index].url ?? '',
                                fit: BoxFit.cover,
                              ),
                            );
                          }))
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          getWeatherFromApi();
          getCatsFromApi();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  ///Perform GET Request to get [Weather] model from the API and return it's result.
  Future<void> getWeatherFromApi() async {
    //set state of loading to start loading.
    setState(() {
      _isLoading = true;
    });
    final result = await _client.get(_forecastEndpoint,
        shouldHandleUnauthorizedRequest: false,
        //your custom queries.
        query: {
          'latitude': '30.04',
          'longitude': '31.23',
          'current_weather': 'true',
        },
        //Function to convert response from json to weather model.
        fromJson: Weather.fromJson);

    result.when(
        //The request was performed successfully and returned the weather model.
        success: (weather) {
      setState(() {
        _isLoading = false;
        _weatherMsg = "${weather.currentWeather?.temperature ?? 0} C";
      });
    },
        //There was an error while performing the request and returned an instance of NetworkException.
        error: (error) {
      //handle error here
      _weatherMsg = "Error is : ${error.message}";
      setState(() {
        _isLoading = false;
      });
    });
  }

  ///Perform GET Request to get List of [Cat] from the API and return it's result.
  ///If successful it returns list of cats.
  ///If not successful it returns an instance of [NetworkException].
  Future<void> getCatsFromApi() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _client.getList(_catsUrl,
        query: {
          'limit': '10',
        },
        fromJson: Cat.fromJson,
        settings: settings.copyWith(
          logSettings: const HyperNetLoggerSettings(
              responseBody: false, attachLoggerOnDebug: true),
        ));

    result.when(success: (cats) {
      setState(() {
        _isLoading = false;
        _cats = cats;
      });

      if (kDebugMode) {
        print('Cats are : ${cats.length}');
      }
    }, error: (error) {
      if (kDebugMode) {
        print('Error is : ${error.message}');
      }
      //handle error here
      _weatherMsg = "Error is : ${error.message}";
      setState(() {
        _isLoading = false;
      });
    });
  }

  // We can map the result to another type like this example:
  // As it converts lis of cats to list of cats image urls.
  NetworkResult<List<String?>> mapCatToImageUrls(
      NetworkResult<List<Cat>> result) {
    return result.map(success: (success) {
      final data = success.data;
      final images = data.map((e) => e.url).toList();
      return NetworkResult.success(images);
    }, error: (error) {
      return NetworkResult<List<String?>>.error(error.error);
    });
  }
}
