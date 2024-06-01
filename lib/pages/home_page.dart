import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:remotevision/auth.dart';
import 'package:remotevision/classes/robot.dart';

final Logger _logger = Logger();

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Robot robot;
  bool _isRobotInitialized = false;
  List<String> availableRobots = [];

  final User? user = Auth().currentuser;

  String? username;

  @override
  void initState() {
    super.initState();
    robot = Robot();
    _loadUsername();
    _initAsync();
  }

  Future<void> _initAsync() async {
    _isRobotInitialized =
        await robot.initialize(onConnectionLost: _handleConnectionLost);
  }

  void _handleConnectionLost() {
    setState(() {
      _isRobotInitialized = false;
    });
    Fluttertoast.showToast(
      msg: 'Robot disconnected',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Widget _reInitButton() {
    return ElevatedButton(
        onPressed: () async {
          robot.initialize();
        },
        child: const Text('Re-init'));
  }

  Widget _testButton() {
    return ElevatedButton(
        onPressed: () async {
          robot.testOutput();
        },
        child: const Text('Test'));
  }

  @override
  void dispose() {
    robot.closePort();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    String? fetchedUsername = await Auth().getUsername();
    setState(() {
      username = fetchedUsername;
    });
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text("RemoteVision");
  }

  Widget _userUID() {
    return Text(user?.email ?? 'User email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  Widget _welcomeText() {
    return Text(
      'Welcome, $username!',
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _robotStatus() {
    if (_isRobotInitialized) {
      return const Text("Robot is online",
          style: TextStyle(color: Colors.green));
    }
    return const Text("Robot is offline", style: TextStyle(color: Colors.red));
  }

  Widget _botControls() {
    return Center(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _reInitButton(),
              _testButton(),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _title(),
            _signOutButton(),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Spacer(),
            if (username != null) _welcomeText(),
            _robotStatus(),
            const Spacer(),
            _botControls(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
