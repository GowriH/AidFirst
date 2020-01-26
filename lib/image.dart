import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:boilermake/main.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' show Context, join;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

String instructions;
String filePath;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

Future<CameraDescription> getCamera() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  return firstCamera;
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}
/*
Future<void> testPython() async {
  StarCoreFactory starcore = await Starflut.getFactory();
  StarServiceClass Service = await starcore.initSimple("test", "123", 0, 0, []);
  await starcore.regMsgCallBackP(
      (int serviceGroupID, int uMsg, Object wParam, Object lParam) async {
    print("$serviceGroupID  $uMsg   $wParam   $lParam");
    return null;
  });
  StarSrvGroupClass SrvGroup = await Service["_ServiceGroup"];
  bool isAndroid = await Starflut.isAndroid();
  if (isAndroid == true) {
    print("HELLO1");
    await Starflut.copyFileFromAssets("test.py", "/starfiles", "/starfiles");
    await Starflut.copyFileFromAssets(
        "python3.6.zip", "fz/starfiles", null); //desRelatePath must be null
    print("HELLO2");
    await Starflut.copyFileFromAssets("zlib.cpython-36m.so", null, null);
    await Starflut.copyFileFromAssets("unicodedata.cpython-36m.so", null, null);
    await Starflut.loadLibrary("libpython3.6m.so");
  }
  String docPath = await Starflut.getDocumentPath();
  print("docPath = $docPath");

  String resPath = await Starflut.getResourcePath();
  print("resPath = $resPath");

  dynamic rr1 = await SrvGroup.initRaw("python36", Service);

  print("initRaw = $rr1");

  var Result = await SrvGroup.loadRawModule(
      "python", "", resPath + "/flutter_assets/starfiles/" + "test.py", false);
  print("loadRawModule = $Result");

  dynamic python = await Service.importRawContext("python", "", false, "");
  print("python = " + await python.getString());

  StarObjectClass retobj = await python.call("tt", ["hello ", "world"]);
  print(await retobj[0]);
  print(await retobj[1]);

  print(await python["g1"]);

  StarObjectClass yy = await python.call("yy", ["hello ", "world", 123]);
  print(await yy.call("__len__", []));

  StarObjectClass multiply =
      await Service.importRawContext("python", "Multiply", true, "");
  StarObjectClass multiply_inst = await multiply.newObject(["", "", 33, 44]);
  print(await multiply_inst.getString());

  print(await multiply_inst.call("multiply", [11, 22]));

  await SrvGroup.clearService();
  await starcore.moduleExit();
}

 */

Future readFileAsString() async {
  instructions = await getFileData('assets/MildCut.txt');
}

Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Use this Picture?",
              style: GoogleFonts.cabin(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 40,
              ),
            ),
            Image.file(
              File(imagePath),
              height: 400,
            ),
            CupertinoButton(
              onPressed: () {
                print("You clicked me");
                readFileAsString();
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => TestScreen(imagePath: "test")));
              },
              padding: EdgeInsets.all(4.0),
              child: Container(
                  height: 100,
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    margin: EdgeInsets.fromLTRB(15, 0, 0, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Click here for First Aid advice",
                        style: GoogleFonts.bangers(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class TestScreen extends StatelessWidget {
  final String imagePath;

  const TestScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    readFileAsString();
    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('Datasets/DisplayImages/MildCutArt.jpg'),
              fit: BoxFit.cover,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Text(
                instructions,
                style: GoogleFonts.cabin(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoButton(
              onPressed: () async {
                final firstcamera = await getCamera();
                //print("Re-routed back to picture screen");
                Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) =>
                            TakePictureScreen(camera: firstcamera)));
              },
              child: Container(
                height: 35,
                width: 200,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Retake picture",
                    style: GoogleFonts.cabin(
                      fontWeight: FontWeight.w400,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              color: Colors.lightBlue,
            ),

            Padding(padding: EdgeInsets.all(3.0)),
            CupertinoButton(
              onPressed: () async {
                final firstcamera = await getCamera();
                //print("Re-routed back to picture screen");
                Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => MyHomePage(title: 'AidFirst')));
              },
              child: Container(
                height: 35,
                width: 200,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Home Screen",
                    style: GoogleFonts.cabin(
                      fontWeight: FontWeight.w400,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              color: Colors.lightBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class FirstAidList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Select the Injury',
      home: Scaffold(
        appBar: AppBar(title: Text('Select the Injury')),
        body: ListBodyLayout(),
      ),
    );
  }
}

class ListBodyLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _injuryListView(context);
  }
}

Widget _injuryListView(BuildContext context) {
  final injuries = [
    'Ant Bite',
    'Bee Sting',
    'Wasp Bite',
    'First Degree Burn',
    'Second Degree Burn',
    'Third Degree Burn',
    'Mild Cut/Scrape',
    'Deep Cut',
    'Bruise',
    'CPR'
  ];

  Future<String> getFileData(String path) async {
    return await rootBundle.loadString(path);
  }

  Future readFileAsString(int index) async {
    final injuryFiles = [
      'AntBite',
      'BeeSting',
      'WaspBite',
      'FirstDegreeBurn',
      'SecondDegreeBurn',
      'ThirdDegreeBurn',
      'MildCut',
      'DeepCuts',
      'Bruise',
      'CPR'
    ];

    String fileName = injuryFiles[index];
    instructions = await getFileData('assets/' + fileName + '.txt');
  }

  String getDisplayImage(int index) {
    final injuryImages = [
      'AntBite.webp',
      'BeeStingArt.jpg',
      'WaspBite.jpeg',
      'FirstDegreeBurnArt.png',
      'SecondDegreeBurnArt.png',
      'ThirdDegreeBurnArt.png',
      'MildCutArt.jpg',
      'DeepCutArt.jpg',
      'BruiseArt.jpg',
      'CPR.webp'
    ];
    return injuryImages[index];
  }

  return ListView.builder(
      itemCount: injuries.length,
      itemBuilder: (context, index) {
        return CupertinoButton(
          padding: EdgeInsets.all(7.0),
          child: Container(
            height: 50,
            width: 375,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage("assets/ant.jpg"),
                  fit: BoxFit.cover,
                )),
            child: Container(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 15,
                ),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      injuries[index],
                      style: GoogleFonts.bangers(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    )),
              ),
            ),
          ),
          onPressed: () async {
            readFileAsString(index);
            int c = index;
            var b = context;
            String imageFile = getDisplayImage(index);
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => TestScreen2(imagePath: imageFile),
                ));
          },
        );
      });
}

class TestScreen2 extends StatelessWidget {
  final String imagePath;

  const TestScreen2({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage('Datasets/DisplayImages/' + imagePath),
              //'Datasets/DisplayImages/WaspBite.jpeg'),
              fit: BoxFit.cover,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Text(
                instructions,
                style: GoogleFonts.cabin(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
