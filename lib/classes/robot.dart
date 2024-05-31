import 'package:usb_serial/usb_serial.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:logger/logger.dart';

class Robot {
  late UsbPort _port;
  final Logger _logger = Logger();
  bool _isInitialized = false;

  Future<bool> initialize() async {
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
          112500,
          UsbPort.DATABITS_8,
          UsbPort.STOPBITS_1,
          UsbPort.PARITY_NONE,
        );
        _isInitialized = true;
        return true;
      }
    } catch (e) {
      _logger.e('Error initializing USB serial communication: $e');
      return false;
    }
    return false;
  }

  Future<String?> requestRobotName() async {
    if (!_isInitialized) {
      _logger.e('Serial port not initialized');
      return null;
    }

    try {
      // Send connection request
      Uint8List requestData = Uint8List.fromList('REQUEST_NAME\n'.codeUnits);
      await _port.write(requestData);

      // Read response from the robot
      Completer<String> completer = Completer<String>();
      List<int> responseBuffer = [];

      _port.inputStream?.listen((Uint8List data) {
        responseBuffer.addAll(data);
        // Assuming the robot sends a newline character at the end of the name
        if (data.contains(10)) {
          // 10 is the ASCII code for newline
          String response = String.fromCharCodes(responseBuffer);
          completer.complete(response.trim());
        }
      });

      String response = await completer.future;
      _logger.d('Received response: $response');
      return response;
    } catch (e) {
      _logger.e('Failed to request robot name: $e');
      return null;
    }
  }

  Future<String?> initializeAndRequestName() async {
    if (await initialize()) {
      return await requestRobotName();
    }
    return null;
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
