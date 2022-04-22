import 'package:flutter/material.dart';
import './bluetooth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Gymy Ble Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Gymy Ble Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final logger = Logger();
  final BluetoothServiceControl _btService = BluetoothServiceControl();
  final _stationTextController = TextEditingController(text: "2");
  final _exerciseTextController = TextEditingController(text: "105");
  bool _bluetoothEnabled = true;
  bool _connected = false;
  bool _stationActivated = false;
  bool _exerciseActivated = false;
  String _labelText = "";

  int _lastStation = 0;

  @override
  void initState() {
    super.initState();
    logger.d("init");
    _btService.setLogger(logger);
    _btService.bluetoothOnStream().listen((state) {
      _bluetoothEnabled = state;
      setState(() {});
    });

    _btService.getConnectionController().listen((state) {
      _connected = state;
      setState(() {});
    });

    _btService.getMsgStream().listen((msg) {
      _labelText = msg.toString();
      if (msg["status_code"] == 1) {
        switch (msg["response"]) {
          case 501:
            _stationActivated = true;
            break;
          case 502:
            _stationActivated = false;
            break;
          case 503:
            _exerciseActivated = true;
            break;
          case 504:
            _exerciseActivated = false;
            break;
        }
      } else {
        showToast('Kein erfolg Ted, status_code:' + (msg["status_code"]).toString());
      }
      setState(() {});
    });
    _stationTextController.text = "2";
    _exerciseTextController.text = "105";
    //setState(() {});
  }

  showToast(String toastMSG) {
    Fluttertoast.showToast(msg: toastMSG);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            SwitchListTile(
              title: const Text('Enable Bluetooth'),
              value: _bluetoothEnabled,
              onChanged: (bool value) {
                if (value) {
                  _btService.turnBluetoothOn();
                }
                else {
                  _btService.turnBluetoothOff();
                }
              },
            ),
            ListTile(
              title: const Text('Connection Status'),
              subtitle: (_connected
                    ? const Text('Connected')
                    : const Text('Disconnected')),
              trailing: ElevatedButton(
                child: (_connected
                    ? const Text('Disconnect')
                    : const Text('Connect')),
                onPressed: () {
                  if(_connected) {
                    logger.d("diconnect clicked");
                    _btService.disconnectFromServer();
                  }
                  else {
                    logger.d("connect clicked");
                    _btService.connectToServer();
                  }
                  setState(() {});
                },
              ),
            ),
            ListTile(
              title: const Text('Start station'),
              subtitle: (_stationActivated
                    ? const Text('Station 2 activated')
                    : const Text('Station 2 deactivated')),
              trailing: SizedBox(
                width: 180,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 30,
                        width: 10,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "station id",
                          ),
                          controller: _stationTextController,
                        ),
                      )
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: 30,
                        child:ElevatedButton(
                          child: (_stationActivated
                              ? const Text('Stop')
                              : const Text('Start')),
                          onPressed: () {
                            //logger.d("station clicked");
                            int id = int.parse(_stationTextController.text, onError: (e) => -1);
                            if (id < 0) {
                              logger.w("Station ID must be a Number");
                              _stationTextController.text = "2";
                              return;
                            }
                            if(!_stationActivated) {
                              _lastStation = id;
                              logger.d("Start Station $id");
                              _btService.loginStation(id);
                            }
                            else {
                              logger.d("Start Station $id");
                              _btService.logoutStation(id);
                            }
                          },
                        )
                      )
                    )
                  ]
                )
              )
            ),
            ListTile(
              title: const Text('Start Exercise'),
              subtitle: (_exerciseActivated
                    ? const Text('Deadlifts activated')
                    : const Text('Deadlifts deactivated')),
              trailing: SizedBox(
                width: 180,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 30,
                        width: 10,
                        child: TextField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "exercise id",
                          ),
                          controller: _exerciseTextController,
                        ),
                      )
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: 30,
                        child:ElevatedButton(
                          child: (_exerciseActivated
                              ? const Text('Stop')
                              : const Text('Start')),
                          onPressed: () {

                            int id = int.parse(_exerciseTextController.text, onError: (e) => -1);
                            if (id < 0) {
                              logger.w("Exercise ID must be a Number");
                              _exerciseTextController.text = "105";
                              return;
                            }
                            if(!_exerciseActivated) {
                              logger.d("Start Exercise $id on Station $_lastStation");
                              _btService.startExercise(_lastStation, id, 1);
                            }
                            else {
                              logger.d("Stop Exercise $id on Station $_lastStation");
                              _btService.stopExercise(_lastStation, id, 1);
                            }
                          },
                        )
                      )
                    )
                  ]
                )
              )
              ,
            ),
            TextField(
                enabled: false,
                maxLines: 8,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Received: \n" + _labelText,
                ),
              ),
          ]
        )
      )// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
