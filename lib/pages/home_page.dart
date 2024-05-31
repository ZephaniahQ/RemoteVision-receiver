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
  String _robotName = '';
  List<String> availableRobots = [];

  final User? user = Auth().currentuser;

  String? username;

  @override
  void initState() {
    super.initState();
    robot = Robot();
    _checkForRobots();
    _loadUsername();
  }

  Future<void> _checkForRobots() async {
    try {
      String? robotName = await robot.initializeAndRequestName();
      if (robotName != null) {
        setState(() {
          _robotName = robotName;
          availableRobots.add(robotName);
          _isRobotInitialized = true;
        });
        Fluttertoast.showToast(
          msg: 'Robot initialized successfully with name $robotName',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to get robot name',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      _logger.e('Failed to initialize and request robot name: $e');
      Fluttertoast.showToast(
        msg: 'Failed to initialize and request robot name: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }

    @override
    void dispose() {
      robot.closePort();
      super.dispose();
    }
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

  Widget _buildRobotCard(String robotName) {
    return Card(
      child: ListTile(
        title: Text(robotName),
        subtitle: Text('Connected Robot'),
        trailing: Icon(Icons.smart_toy),
      ),
    );
  }

  Widget _robotsList() {
    return _isRobotInitialized
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Robots',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: availableRobots.length,
                  itemBuilder: (context, index) {
                    return _buildRobotCard(availableRobots[index]);
                  },
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _welcomeText(),
              const SizedBox(height: 20),
              _robotsList(),
              const Spacer(),
            ],
          ),
        ));
  }
}
