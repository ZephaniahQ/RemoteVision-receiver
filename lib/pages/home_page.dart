import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:remotevision/auth.dart';
import 'package:remotevision/classes/robot.dart';
import 'package:remotevision/classes/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final Logger _logger = Logger();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Robot robot;
  bool _isRobotInitialized = false;
  final Auth auth = Auth();
  final User? user = Auth().currentuser;

  String? username;

  // WebRTC components
  Signaling signaling = Signaling();
  MediaStream? localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;

  @override
  void initState() {
    super.initState();
    robot = Robot();
    _loadUsername();
    _initAsync();
    _initializeWebRTC();
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

  Future<void> _initializeWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await signaling.openUserMedia(_localRenderer, _remoteRenderer);
    setState(() {
      localStream = signaling.localStream;
    });
  }

  Future<void> _createRoom() async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    // Check if there are existing rooms and delete them
    var existingRooms = await db.collection('rooms').get();
    for (var room in existingRooms.docs) {
      await db.collection('rooms').doc(room.id).delete();
      _logger.i('Deleted existing room with ID: ${room.id}');
    }

    roomId = await signaling.createRoom(_remoteRenderer);
    if (roomId != null) {
      Fluttertoast.showToast(
        msg: 'Room created with ID: $roomId',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  void dispose() {
    robot.closePort();
    signaling.hangUp();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    String? fetchedUsername = await auth.getUsername();
    setState(() {
      username = fetchedUsername;
    });
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Widget _title() {
    return const Text("RemoteVision");
  }

  // Widget _userUID() {
  //   return Text(user?.email ?? 'User email');
  // }

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
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createRoom,
            child: const Text('Create WebRTC Room'),
          ),
        ],
      ),
    );
  }

  Widget _reInitButton() {
    return ElevatedButton(
      onPressed: () async {
        robot.initialize();
      },
      child: const Text('Re-init'),
    );
  }

  Widget _testButton() {
    return ElevatedButton(
      onPressed: () async {
        robot.testOutput();
      },
      child: const Text('Test'),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 10),
          _welcomeText(),
          const SizedBox(height: 20),
          _robotStatus(),
          const SizedBox(height: 20),
          _botControls(),
          const SizedBox(height: 20),
          Expanded(child: RTCVideoView(_localRenderer)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
