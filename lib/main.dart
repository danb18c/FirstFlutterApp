import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

void main() {
  runApp(MyApp());
}

class SimpleList {
  List<ListItem> items;

  SimpleList() {
    items = new List();
  }

  toJSONEncodable() {
    return items.map((item) {
      return item.toJSONEncodable();
    }).toList();
  }
}

class ListItem {
  String title;
  bool done;

  ListItem({this.title, this.done});

  toJSONEncodable() {
    Map<String, dynamic> m = new Map();

    m['title'] = title;
    m['done'] = done;

    return m;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'List App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ListHomePage(title: 'List'),
    );
  }
}

class ListHomePage extends StatefulWidget {
  ListHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ListHomePageState createState() => _ListHomePageState();
}

class _ListHomePageState extends State<ListHomePage> {
  final SimpleList list = new SimpleList();
  final LocalStorage storage = new LocalStorage('list_app');
  bool initialized = false;
  TextEditingController controller = new TextEditingController();

  void _toggleItem(ListItem item) {
    setState(() {
      item.done = !item.done;
      _saveToStorage();
    });
  }

  void _addItem(String title) {
    setState(() {
      final item = new ListItem(title: title, done: false);
      list.items.add(item);
      _saveToStorage();
    });
  }

  void _saveToStorage() {
    storage.setItem('todos', list.toJSONEncodable());
  }

  void _clearStorage() async {
    await storage.clear();

    setState(() {
      list.items = storage.getItem('todos') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        constraints: BoxConstraints.expand(),
        child: FutureBuilder(
            future: storage.ready,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.data == null) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!initialized) {
                var items = storage.getItem('todos');

                if (items != null) {
                  list.items = List<ListItem>.from(
                    (items as List).map(
                      (item) =>
                          ListItem(title: item['title'], done: item['done']),
                    ),
                  );
                }

                initialized = true;
              }

              List<Widget> widgets = list.items.map((item) {
                return CheckboxListTile(
                    value: item.done,
                    title: Text(item.title),
                    selected: item.done,
                    onChanged: (bool selected) {
                      _toggleItem(item);
                    });
              }).toList();

              return Column(
                children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: ListView(
                        children: widgets,
                        itemExtent: 50.0,
                      )),
                  ListTile(
                      title: TextField(
                        controller: controller,
                        decoration:
                            InputDecoration(labelText: 'Add an item...'),
                        onEditingComplete: _save,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.save),
                            onPressed: _save,
                            tooltip: 'Save',
                          ),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: _clearStorage,
                              tooltip: 'Clear Storage')
                        ],
                      ))
                ],
              );
            }),
      ),
    );
  }

  void _save() {
    _addItem(controller.value.text);
    controller.clear();
    FocusScope.of(context).unfocus();
  }
}
