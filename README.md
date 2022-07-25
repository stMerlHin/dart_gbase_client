<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->


This package is dart driver for gbase service.

#Version
 ``1.0.0
 ``

## Features

* Query remote sql database through gbase http server
* Listen to change on remote sql database through gbase http server
* Download and upload large files through gbase http server
* Online, see at and offline features support

## Getting started

To add this package to your dart or flutter project, just add these line to your 
pubspec.yaml file under 

```yaml
dependencies:
  dart_gbase_client:
    git:
      url: git://github.com/stMerlHin/dart_gbase_client.git
      ref: stable
```



## Usage

```dart
import 'package:dart_gbase_client/dart_gbase_client';
///We assumed that a gbase server is already set up at 127.0.0.1 on port 8080
////How to initialize.
///Initialization must be make once
  late GBase _gbase;
  GBase.instance.initialize(
      host: 'localhost',
      ///Called when the initialization is completed
      onInitialization: (gBase) {
        _gBase = gBase;
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
      ///Called when the reconnection is successful
      onReconnection: (connectionId) {
        print('reconnected');
        print(connectionId);
      });
  
  ///Gbase should be dispose properly
_gbase.dispose();
```

## Additional information

Gbase is a personal project which goal is to provide service like firebase does.
This package is a simple 'mini sdk' for flutter framework. Package for platforms like 
java, javascript and php are available under 
http://www.github.com/gbase_clients/<language>_gbase_client
