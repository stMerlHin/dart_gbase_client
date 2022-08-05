// Copyright (c) 2022. st MerlHin from GUILEAD.
// All rights reserved. Use of this source code is governed by a
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dart_gbase_client/dart_gbase_client.dart';

void main() {
  print('awesome: Yeah');
  late GBase _gbase;


  GBase.instance.initialize(
      host: 'localhost',
      port: '8080',

      ///Called when the initialization is completed
      onInitialization: (gBase) {
        print('initialized');
        // GTask.fileDownload(
        //     theUrl: 'http://localhost:8080/download/d',
        //     savePath: 'bb.mp4',
        //     onDownloadProgress: (d) {
        //       print(d);
        //     }
        // );



      },

      ///Called when the connection is successful
      onConnection: (String connectionId, GBase base) {
        print('Connected');
        print(connectionId);
        Timer(Duration(microseconds: 500), () async {
          print('ok');
          for(int i = 0; i < 4000; i++) {
            TableListener(table: 'etudiant').listen(() {});
          }
        });
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
}
