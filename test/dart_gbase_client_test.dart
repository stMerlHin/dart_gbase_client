// Copyright (c) 2022. st MerlHin from GUILEAD.
// All rights reserved. Use of this source code is governed by a
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_gbase_client/dart_gbase_client.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      print('awesome: Yeah');
      bool init = false;
      bool configure = false;
      late GBase _gbase;
      GBase.instance.initialize(
          host: 'localhost',
          port: '8080',
          ///Called when the initialization is completed
          onInitialization: (gBase) {
            print('initialized');
            _gbase = gBase;
            init = true;

          },
          ///Called when the connection is successful
          onConnection: (String connectionId, GBase base) {
            print('Connected');
            print(connectionId);
          },
          ///Called when the connection is closed due to an error
          onDisconnection: (base) {
            print('disconnected');
          },
          ///Called when the reconnection is in progress
          onReconnection: (connectionId) {
            print('reconnection in progress');
            print(connectionId);
          },
          ///Called when configuration are changed
          onConfigChanged: (connectionId) {
            print('configuration changed');
          });

      Timer(Duration(seconds: 3), () async {
        await _gbase.changeConfig(port: '80');
        print('HERE WE GO');
      });
      Timer(Duration(seconds: 7), () async {
        await _gbase.changeConfig(port: '8080');
        print('OK OK OK ');
      });
      //expect(true, isTrue);
    });
  });
}
