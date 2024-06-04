import 'package:fluttertoast/fluttertoast.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:logger/logger.dart';

class Robot {
  late UsbPort _port;
  final Logger _logger = Logger();
  bool _isInitialized = false;
  Timer? _connectionCheckTimer;
  Function? onConnectionLost; // Callback for connection lost

  Future<bool> initialize({Function? onConnectionLost}) async {
    this.onConnectionLost = onConnectionLost;
    try {
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isNotEmpty) {
        _port = (await devices[0].create())!;
        bool openResult = await _port.open();
        if (!openResult) {
          _logger.e("Failed to open port");
          return false;
        }
        await _port.setDTR(true);
        await _port.setRTS(true);
        await _port.setPortParameters(
          115200,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );
        _isInitialized = true;
        _startConnectionCheckTimer();
        return true;
      } else {
        Fluttertoast.showToast(msg: 'No USB devices found');
      }
    } catch (e) {
      _logger.e('Error initializing USB serial communication: $e');
      Fluttertoast.showToast(msg: 'Error initializing USB: $e');
    }
    return false;
  }

  void _startConnectionCheckTimer() {
    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!await _isConnectionActive()) {
        _isInitialized = false;
        _logger.e('Connection lost');
        Fluttertoast.showToast(msg: 'Connection lost');
        onConnectionLost?.call(); // Call the callback
        _connectionCheckTimer?.cancel();
      }
    });
  }

  Future<bool> _isConnectionActive() async {
    try {
      await sendSerial(
          'P'); // Send a ping message or any other message to check the connection
      // If no exception, the connection is still active
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> testOutput() async {
    if (_isInitialized) {
      await sendSerial('F');
      await sendSerial('B');
      await sendSerial('L');
      await sendSerial('R');
    } else {
      Fluttertoast.showToast(msg: "Robot offline unable to test");
    }
  }

  Future<void> sendSerial(String message) async {
    try {
      Uint8List data = Uint8List.fromList(message.codeUnits);
      await _port.write(data);
      _logger.d('Message sent: $message');
    } catch (e) {
      _logger.e('Failed to send message');
    }
  }

  void closePort() {
    if (_isInitialized) {
      _port.close();
      _logger.d('Port closed');
      _isInitialized = false;
    } else {
      _logger.e('Port was not initialized');
    }
  }
}
