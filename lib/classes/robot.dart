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

  Future<String?> requestName() async {
    try {
      // Send 'N' character to request the robot's name
      await sendSerial('N');
      // Read the response
      Uint8List data = (await _port.inputStream!.toList()).first;
      String name = String.fromCharCodes(data);
      _logger.d('Received robot name: $name');
      return name.trim();
    } catch (e) {
      _logger.e('Failed to request robot name: $e');
      return null;
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

  Future<String?> initializeAndRequestName() async {
    if (await initialize()) {
      return await requestName();
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
