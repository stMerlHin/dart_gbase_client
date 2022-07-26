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

# Version
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
n
```yaml
dependencies:
  dart_gbase_client:
    git:
      url: https://github.com/stMerlHin/dart_gbase_client.git
      ref: stable
```



# Usage

#### Initialization
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
        _gbase = gBase;
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
        print('reconnected');
        print(connectionId);
      },
      ///Called when configuration are changed
      onConfigChanged: (connectionId) {
        print('configuration changed');
  });
```
### Change configurations
To change the server's address and port
```dart
_gbase.changeConfig(host: '127.0.0.1', port: '80');
```

### Listen to table
```dart
TableListener tableListener = TableListener(table: 'student');
    tableListener.listen(() {
      print('Change HAPPENED ON TABLE student');
    });
```

Table listener must be disposed properly if it's not needed anymore.
```dart
tableListener.dispose();
```

### Query
#### Select
```dart
///Select query
GDirectRequest.select(
        sql: 'SELECT * FROM student WHERE id = ? ',
        table: 'student',
        values: [3]
   ).exec(
        ///results is always an array of array
        onSuccess: (results) {
          results.data.forEach((element) {
            print(element);

          });
        }, onError: (error) {
          print(error);
    });
```

## Additional information

Gbase is a personal project which goal is to provide features which miss when using databases.
This package is a simple 'mini sdk' for dart and flutter framework. 
Package for platforms like 

[comment]: <> (java, javascript and php are available under )

[comment]: <> (http://www.github.com/stmerlhin/<language>_gbase_client)
