// Copyright (c) 2022. st MerlHin from GUILEAD.
// All rights reserved. Use of this source code is governed by a
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_gbase_client/src/constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:web_socket_channel/web_socket_channel.dart';

//How to initialize.
//Initialization must be make once
// late GBase _gbase;
// GBase.instance.initialize(
//         gHost: 'localhost',
//         onInitialization: (gBase) {
//           _gBase = gBase;
//         },
//         onConnection: (String connectionId, GBase base) {
//           print('Connected');
//           print(connectionId);
//         },
//         onDisconnection: (base) {
//           print('disconnected');
//         },
//         onReconnection: (connectionId) {
//           print('reconnected');
//           print(connectionId);
//         }
//     );
class GBase {
  late WebSocketChannel _channel;
  static String _gHost = kLocalhost;
  static String _gPort = kPort;
  static String _connectionId = '';
  static late int _autoReconnectionDelay;
  static bool _autoReconnect = true;
  static bool _isConnected = false;
  static bool _initialized = false;
  late Function(GBase) _onInitialization;
  late Function(GBase) _onDisconnection;
  late Function(String) _onReconnection;
  late Function(String, GBase) _onConnection;
  late Function(String, GBase) _onError;
  late Function(Map<String, String>) _onConfigChanged;
  bool _disconnect = false;

  static final GBase _instance = GBase._();

  GBase._();

  ///Initialize gbase client
  Future initialize({
    bool autoReconnect = true,
    int autoReconnectionDelay = 2,
    String host = kLocalhost,
    String port = kPort,
    Function(GBase)? onDisconnection,
    required Function(GBase) onInitialization,
    Function(String)? onReconnection,
    Function(String, GBase)? onConnection,
    Function(String, GBase)? onError,
    Function(Map<String, String>)? onConfigChanged,
  }) async {
    _onInitialization = onInitialization;
    if (!_initialized) {
      _gHost = host;
      _gPort = port;

      _autoReconnect = autoReconnect;
      _onConnection = onConnection ?? (s, g){};
      _onReconnection = onReconnection ?? (s){};
      _autoReconnectionDelay = autoReconnectionDelay;
      _onConfigChanged = onConfigChanged ?? (d) {};
      _onError = onError ?? (e, g){};
      _onDisconnection = onDisconnection ?? (s){};

      await _connect();
      _onInitialization(this);
      _initialized = true;
    }
  }

  Future reconnect() async {
    dispose();
    await _connect();
  }

  Future _connect() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://$_gHost:$_gPort/ws'));

    ///Request connection id
    _channel.sink.add('');

    _channel.stream.listen((event) {
      //TODO should save the connection id
      _connectionId = event;
      _isConnected = true;

      _onConnection(event, this);
    }, onError: (e) {
      _onError(e.toString(), this);
    }).onDone(() async {
      _onDisconnection(this);

      ///Automatically reconnect the client if connection is closed in none
      ///appropriate way
      if (_autoReconnect && !_disconnect) {
        Timer(Duration(seconds: _autoReconnectionDelay), () async {
          _onReconnection(_connectionId);
          await _connect();
        });
        //await Future.delayed(Duration(seconds: _autoReconnectionDelay));
      }
    });
  }

  ///Change the configurations relative to remote server
  void changeConfig({String? host, String? port}) {
    bool configChanged = false;
    if (host != null) {
      _gHost = host;
      configChanged = true;
    }
    if (port != null) {
      _gPort = port;
      configChanged = true;
    }
    if (configChanged) {
        _onConfigChanged({'host': _gHost, 'port': _gPort});
      _connect();
    }
  }

  static GBase get instance => _instance;
  bool get isConnected => _isConnected;
  static String get connectionId => _connectionId;
  static String get baseUrl => 'ws://$_gHost:$_gPort/ws/';

  String get host => _gHost;

  String get port => _gPort;

  Future dispose() async {
    _disconnect = true;
    await _channel.sink.close();
  }
}

//  TableListener tableListener = TableListener(table: 'student');
//     tableListener.listen(() {
//       print('Change HAPPENED ON TABLE student');
//     });
class TableListener {
  late WebSocketChannel _webSocket;
  bool _closeByClient = false;
  late String _connectionId;
  String table;
  late int _reconnectionDelay;

  TableListener({required this.table});

  void listen(Function onChanged, {int reconnectionDelay = 1000}) {
    _connectionId = GBase.connectionId;
    _reconnectionDelay = reconnectionDelay;
    _create(onChanged);
  }

  void _create(Function onChanged) {
    _webSocket = _createChannel('db/listen');
    _webSocket.sink.add(_toJson());
    _webSocket.stream.listen((event) {
      onChanged();
    }).onDone(() {
      if (!_closeByClient) {
        Timer(Duration(milliseconds: _reconnectionDelay), () {
          _create(onChanged);
        });
      }
    });
  }

  String _toJson() {
    return jsonEncode({
      kConnectionId: _connectionId,
      kTable: table,
    });
  }

  void dispose() {
    _closeByClient = true;
    _webSocket.sink.close();
  }
}

WebSocketChannel _createChannel(String url) {
  return WebSocketChannel.connect(Uri.parse('${GBase.baseUrl}' '$url'));
}

// an example of use.
// we want to get all user with 3 as id
//GDirectRequest.select(
//         sql: 'SELECT * FROM student WHERE id = ? ',
//         table: 'student',
//         values: [3]
//    ).exec(
//         onSuccess: (results) {
//           results.data.forEach((element) {
//             print(element);
//
//           });
//         }, onError: (error) {
//           print(error);
//     });
class GDirectRequest {
  String connectionId;
  String sql;
  GRequestType type;
  String table;
  List<dynamic>? values;

  GDirectRequest(
      {required this.connectionId,
        required this.sql,
        required this.type,
        required this.table,
        this.values});

  factory GDirectRequest.select({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.select,
        table: table,
        values: values);
  }

  factory GDirectRequest.insert({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.insert,
        table: table,
        values: values);
  }

  factory GDirectRequest.update({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.update,
        table: table,
        values: values);
  }

  factory GDirectRequest.delete({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.delete,
        table: table,
        values: values);
  }

  factory GDirectRequest.create({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.create,
        table: table,
        values: values);
  }

  factory GDirectRequest.drop({
    required String sql,
    required String table,
    List<dynamic>? values,
  }) {
    return GDirectRequest(
        connectionId: GBase.connectionId,
        sql: sql,
        type: GRequestType.drop,
        table: table,
        values: values);
  }

  String _toJson() {
    return jsonEncode({
      kConnectionId: connectionId,
      kTable: table,
      kType: type.toString(),
      kValues: values,
      kSql: sql
    });
  }

  exec({
    required Function(GResult) onSuccess,
    required Function(String) onError,
  }) async {
    //check if the client is connected
    if (GBase._isConnected) {
      WebSocketChannel webSocket = _createChannel('db/request');
      bool closed = false;
      webSocket.stream.listen((event) {
        GResult result = GResult.fromJson(event);
        if (result.errorHappened) {
          onError(result.error);
          closed = true;
          //Close the channel after response got
          webSocket.sink.close();
        } else {
          onSuccess(result);
          closed = true;
          //Close the channel after response got
          webSocket.sink.close();
        }
      }).onDone(() {
        if (!closed) {
          onError('Connection closed with no feedback, '
              'Unable to determine if potential changes are'
              ' made or not');
        }
      });
      webSocket.sink.add(_toJson());
    } else {
      onError('This client is not connected');
    }
  }
}

enum GRequestType {
  select,
  update,
  insert,
  create,
  drop,
  delete;

@override
String toString() {
  switch (this) {
    case GRequestType.select:
      return 'select';
    case GRequestType.update:
      return 'update';
    case GRequestType.insert:
      return 'insert';
    case GRequestType.delete:
      return 'delete';
    case GRequestType.create:
      return 'create';
    case GRequestType.drop:
      return 'drop';
  }
}
}

class GResult {
  final List<dynamic> data;
  final bool errorHappened;
  final String error;

  GResult({this.data = const [], this.errorHappened = false, this.error = ''});

  static GResult fromJson(String json) {
    var map = jsonDecode(json);
    return GResult(
        data: map[kData],
        errorHappened: map[kErrorHappened],
        error: map[kError]);
  }
}

typedef OnDownloadProgressCallback = void Function(
    int receivedBytes, int totalBytes);
typedef OnUploadProgressCallback = void Function(int percent);

class GTask {
  static bool trustSelfSigned = true;

  static HttpClient getHttpClient() {
    HttpClient httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => trustSelfSigned);

    return httpClient;
  }

  static fileGetAllMock() {
    return List.generate(
      20,
          (i) => GUpDownMod(
          fileName: 'filename $i.jpg',
          dateModified: DateTime.now().add(Duration(minutes: i)),
          size: i * 1000),
    );
  }
  //
  // static Future<List<GUpDownMod>> fileGetAll() async {
  //   var httpClient = getHttpClient();
  //
  //   final url = '$baseUrl/api/file';
  //
  //   var httpRequest = await httpClient.getUrl(Uri.parse(url));
  //
  //   var httpResponse = await httpRequest.close();
  //
  //   var jsonString = await readResponseAsString(httpResponse);
  //
  //   return fileFromJson(jsonString);
  // }

  // static Future<String> fileDelete(String fileName) async {
  //   var httpClient = getHttpClient();
  //
  //   final url = Uri.encodeFull('$baseUrl/api/file/$fileName');
  //
  //   var httpRequest = await httpClient.deleteUrl(Uri.parse(url));
  //
  //   var httpResponse = await httpRequest.close();
  //
  //   var response = await readResponseAsString(httpResponse);
  //
  //   return response;
  // }

  static Future<String> fileUpload(
      {required File file, OnUploadProgressCallback? onUploadProgress}) async {
    final url = '${GBase.baseUrl}/api/file';

    final fileStream = file.openRead();

    int totalByteLength = file.lengthSync();

    final httpClient = getHttpClient();

    final request = await httpClient.postUrl(Uri.parse(url));

    request.headers.set(HttpHeaders.contentTypeHeader, ContentType.binary);

    request.headers.add("filename", path.basename(file.path));

    request.contentLength = totalByteLength;

    int byteCount = 0;
    Stream<List<int>> streamUpload = fileStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;

          if (onUploadProgress != null) {
            onUploadProgress(((byteCount / totalByteLength) * 100).toInt());
            // CALL STATUS CALLBACK;
          }

          sink.add(data);
        },
        handleError: (error, stack, sink) {
          print(error.toString());
        },
        handleDone: (sink) {
          sink.close();
          // UPLOAD DONE;
        },
      ),
    );

    await request.addStream(streamUpload);

    final httpResponse = await request.close();

    if (httpResponse.statusCode != 200) {
      throw Exception('Error uploading file');
    } else {
      return await readResponseAsString(httpResponse);
    }
  }

  static Future fileUploadMultipart({
    required File file,
    required Function(String) onSuccess,
    required Function(String) onError,
    OnUploadProgressCallback? onUploadProgress,
    required MediaType mediaType,
    required String destination,
  }) async {
    final url = destination;

    final httpClient = getHttpClient();

    final request = await httpClient.postUrl(Uri.parse(url));

    int byteCount = 0;
    int percentage = 0;

    var multipart = await http.MultipartFile.fromPath(
        path.basename(file.path), file.path,
        contentType: mediaType);

    // final fileStreamFile = file.openRead();

    // var multipart = MultipartFile("file", fileStreamFile, file.lengthSync(),
    //     filename: fileUtil.basename(file.path));

    http.MultipartRequest requestMultipart =
    http.MultipartRequest("POST", Uri.parse(url));

    requestMultipart.files.add(multipart);

    var msStream = requestMultipart.finalize();

    var totalByteLength = requestMultipart.contentLength;

    request.contentLength = totalByteLength;

    request.headers.set(HttpHeaders.contentTypeHeader,
        requestMultipart.headers[HttpHeaders.contentTypeHeader]!);

    Stream<List<int>> streamUpload = msStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);

          byteCount += data.length;

          if (onUploadProgress != null) {
            if (percentage != ((byteCount / totalByteLength) * 100).toInt()) {
              onUploadProgress(((byteCount / totalByteLength) * 100).toInt());
              percentage = ((byteCount / totalByteLength) * 100).toInt();
            }
            // CALL STATUS CALLBACK;
          }
        },
        handleError: (error, stack, sink) {
          throw error;
        },
        handleDone: (sink) {
          sink.close();
          // UPLOAD DONE;
        },
      ),
    );

    await request.addStream(streamUpload);

    final httpResponse = await request.close();
//
    var statusCode = httpResponse.statusCode;

    if (statusCode ~/ 100 != 2) {
      onError(httpResponse.reasonPhrase);
    } else {
      onSuccess(await readResponseAsString(httpResponse));
      //return await readResponseAsString(httpResponse);
    }
  }

  static imageUpload({
    required File file,
    required Function(String) onError,
    required Function(String) onSuccess,
    OnUploadProgressCallback? onUploadProgress,
  }) async {
    GTask.fileUploadMultipart(
        onSuccess: onSuccess,
        onError: onError,
        file: file,
        destination:
        'http://${GBase._gHost}:${GBase._gPort}/upload/covers/${path.basename(file.path)}/${path.extension(file.path).replaceRange(0, 1, '')}',
        onUploadProgress: onUploadProgress,
        mediaType: MediaType(
            'image', path.extension(file.path).replaceRange(0, 1, '')));
  }

  static docUpload({
    required File file,
    required Function(String) onError,
    required Function(String) onSuccess,
    OnUploadProgressCallback? onUploadProgress,
  }) async {
    GTask.fileUploadMultipart(
        file: file,
        onError: onError,
        destination:
        'http://${GBase._gHost}:${GBase._gPort}/upload/book/${path.basename(file.path)}/${path.extension(file.path).replaceRange(0, 1, '')}',
        onUploadProgress: onUploadProgress,
        onSuccess: onSuccess,
        mediaType: MediaType(
            'application', path.extension(file.path).replaceRange(0, 1, '')));
  }

  static Future<String> fileDownload(
      {required String theUrl,
        required String savePath,
        OnUploadProgressCallback? onDownloadProgress}) async {
    final url = theUrl;

    final httpClient = getHttpClient();

    final request = await httpClient.getUrl(Uri.parse(url));

    request.headers
        .add(HttpHeaders.contentTypeHeader, "application/octet-stream");

    var httpResponse = await request.close();

    int byteCount = 0;
    int totalBytes = httpResponse.contentLength;

    //appDocPath = "/storage/emulated/0/Download";

    File file = File(savePath);

    var raf = file.openSync(mode: FileMode.write);

    Completer completer = Completer<String>();

    httpResponse.listen(
          (data) {
        byteCount += data.length;

        raf.writeFromSync(data);

        if (onDownloadProgress != null) {
          onDownloadProgress(((byteCount / totalBytes) * 100).toInt());
        }
      },
      onDone: () {
        raf.closeSync();

        completer.complete(file.path);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return await completer.future;
  }

  static Future<String> readResponseAsString(HttpClientResponse response) {
    var completer = Completer<String>();
    var contents = StringBuffer();
    response.transform(utf8.decoder).listen((String data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }
}

List<GUpDownMod> fileFromJson(String str) {
  final jsonData = json.decode(str);
  return List<GUpDownMod>.from(jsonData.map((x) => GUpDownMod.fromJson(x)));
}

String fileToJson(List<GUpDownMod> data) {
  final dyn = List<dynamic>.from(data.map((x) => x.toJson()));
  return json.encode(dyn);
}

class GUpDownMod {
  String fileName;
  DateTime dateModified;
  int size;

  GUpDownMod({
    required this.fileName,
    required this.dateModified,
    required this.size,
  });

  factory GUpDownMod.fromJson(Map<String, dynamic> json) {
    //print( "Datum: ${json["dateModified"]}");

    return GUpDownMod(
      fileName: json["fileName"],
      dateModified: DateTime.parse(json["dateModified"]),
      size: json["size"],
    );
  }

  Map<String, dynamic> toJson() => {
    "fileName": fileName,
    "dateModified": dateModified,
    "size": size,
  };
}
