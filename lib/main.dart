import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

void main() {
  print(UniversalPlatform.isWeb);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: userScreen(),
    );
  }
}

class userScreen extends StatelessWidget {
  TextEditingController s = TextEditingController();
  TextEditingController r = TextEditingController();
  TextEditingController ch = TextEditingController();

  @override
  Widget build(BuildContext context) {
    print("hi");

    var ls = [
      Align(
        child: Container(
          child: Text("dsd"),
          color: Colors.redAccent,
        
        ),
      ),
    Align(
      alignment: Alignment.centerLeft,
      child: Container(
          padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: Colors.grey.shade400),
          child: Text("dsd"),
        
        ),
    ) ,
      Align(
        child: Container(
    
          child: Text("dsd"),
        ),
      ),
      
    ];
    return Scaffold(
      appBar: UniversalPlatform.isAndroid ? AppBar() : null,
      body: Column(children: [


          TextField(controller: s),
          TextField(
            controller: r,
          ) 
          ,
          ElevatedButton(
              onPressed: () {
                final route = MaterialPageRoute(builder: (context) {
                  return MyHomePage(
                      sid: int.parse(s.text),
                      rid: int.parse(r.text),
                      ch: ch.text);
                });
                Navigator.push(context, route);
              },
              child: Text("start chatingpo"))
      ],)
    );
  }
}

class MyHomePage extends StatefulWidget {
  int? sid;
  int? rid;
  String? ch;
  MyHomePage({this.rid, this.sid, this.ch});

  @override
  _MyHomePageState createState() =>
      _MyHomePageState(rid: this.rid, sid: this.sid, ch: this.ch);
}

class _MyHomePageState extends State<MyHomePage> {
  int? sid;
  int? rid;
  String? ch;
  _MyHomePageState({this.rid, this.sid, this.ch});
  StreamSocket sk = StreamSocket();
  List<Widget> lw = [];
  IO.Socket? socket;
  ScrollController sc = ScrollController();
  @override
  void dispose() {
    socket!.dispose();
    socket!.close();
    socket!.disconnect();
    socket!.disconnect();
    print("dipoooosed!!!!!!!!!!!!");
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    print(ch);
    getMes().then((value) {
      print(value);
      ms = value;
      setState(() {});
    }).catchError((err) {
      print("some err$err");
    });
    socket = IO.io(
      'http://192.168.0.95:2000',
      <String, dynamic>{
        'transports': ['websocket'],
        "autoConnect": false,
        "query": "chatRoomId=$sid",
        'forceNew': false
      },
    );

    //socket.emit('carrito:all', {'id': userid});
    socket!.connect();

    socket!.onConnect((v) {
      print("###########" + socket!.id.toString());
      print('connect' + v);
    });
    socket!.on('recievemessage', (data) {
      print("new message");


      if(data["sid"]==rid||data["sid"]==sid)
      sk.addResponse({"message": data["message"], "sid": sid, "rid": rid});
    });
    socket!.onDisconnect((_) {
      socket!.destroy();
      socket!.dispose();
      socket!.close();
      print('sock disconnect!');
    });
    socket!.on('fromServer', (_) => print(_));
    super.initState();
  }

  List<Widget> ms = [];
  int x = 3;
  var m = Message("dsd", "1", "2");
  TextEditingController t = TextEditingController();

  Future<List<Widget>> getMes() async {
    var url = Uri.parse('http://192.168.0.95:2000/message/$sid');

    var response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
      },
    );

    List<dynamic> x = jsonDecode(response.body);
    List<Map<String, dynamic>> ls = List<Map<String, dynamic>>.from(x);
    List<Widget> l = ls.map((e) => Text(e["message"])).toList();
    print(l[0]);

    if (l.length > 0) sk.addResponse({"message": "", "sid": sid, "rid": rid});
    return l;
  }

  @override
  Widget build(BuildContext context) {
    print("widget rebuild");
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final route = MaterialPageRoute(builder: (context) {
              return userScreen();
            });
            Navigator.pushReplacement(context, route);
          },
        ),
        title: Text("chatting"),
      ),
      body: Center(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 1,
              right: 1,
              bottom: 30,
              child: StreamBuilder<Map<String, dynamic>>(
                  stream: sk.getResponse(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snap.hasData) {
                      print("@@@@@@@@@" + snap.data.toString());
                      print("has data");
                      List<Widget> x = ms;
                      ms.add(Text(snap.data!["message"]));
                      print(snap.data?.length);
                      ms = ms.reversed.toList();
                      print(ms);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListView.builder(
                            reverse: true,
                            itemCount: ms.length,
                            itemBuilder: (context, index) {
                              return Container(
                                child: ms[index],
                              );
                            }),
                      );
                    } else {
                      return ms[0];
                    }
                  }),
            ),
            Positioned(
              child: TextField(controller: t),
              bottom: 0,
              left: 1,
              right: 1,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print("hi from browser");
          var url = Uri.parse('http://192.168.0.95:2000/message');
          print(t.text);
          var response = await http.post(url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"message": t.text, "sid": sid, "rid": rid}));
          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');
          // sk.addResponse({"message": t.text, "sid": 1, "rid": 2});
          socket!
              .emit('sendmessage', {'message': t.text, 'sid': sid, "rid": rid});
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Message {
  final String text;
  final String senderID;
  final String receiverID;

  Message(this.text, this.senderID, this.receiverID);
}

class User {
  String name;
  String chatID;

  User(this.name, this.chatID);
}

class StreamSocket {
  var s = StreamController<Map<String, dynamic>>();

  void addResponse(Map<String, dynamic> v) {
    s.sink.add(v);
  }

  Stream<Map<String, dynamic>> getResponse() {
    return s.stream;
  }

  void dispose() {
    s.close();
  }
}
//  Container(
  
       
  
//          color: Colors.green,
  
       
  
//          height: 100,
  
       
  
//          width: 100,
  
       
  
//          child: Text("sd")
  
       
  
//        ),

