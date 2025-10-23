import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoadingProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> runTask(Future<void> Function() task) async {
    try {
      _setLoading(true);
      await task();
    } catch (e) {
      print("Error in LoadingProvider.runTask: $e");

      String errorMessage = e.toString();
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
