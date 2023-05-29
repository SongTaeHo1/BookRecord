import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(BookRecord());
}

class BookRecord extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: BottomNavigation(),
    );
  }
}

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;
  List _selectedItems = [];

  void setSelectedItems(List items) {
    setState(() {
      _selectedItems = items;
    });
  }

  final List<Widget> Function(List, Function) _screens = (items, setSelectedItems) => [
    LibraryScreen(selectedItems: items, setSelectedItems: setSelectedItems),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens(_selectedItems, setSelectedItems)[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '서재',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  final List selectedItems;
  final Function setSelectedItems;

  SearchScreen({required this.selectedItems, required this.setSelectedItems});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String result = '';
  List<dynamic> data = [];
  TextEditingController _editingController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int page = 1;

  @override
  void initState() {
    super.initState();
    _editingController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange) {
        page++;
        getJSONData();
      }
    });
  }

  @override
  void dispose() {
    _editingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _editingController,
          style: TextStyle(color: Colors.white),
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            icon: Icon(Icons.search),
            hintText: '검색어를 입력하세요',
          ),
          onSubmitted: (_) {
            page = 1;
            data.clear();
            getJSONData();
          },
        ),
      ),
      body: Container(
        child: Center(
          child: data.length == 0
              ? Text(
            "데이터가 없습니다",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          )
              : ListView.builder(
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (widget.selectedItems.contains(data[index])) {
                    widget.selectedItems.remove(data[index]);
                  } else {
                    widget.selectedItems.add(data[index]);
                  }
                  setState(() {});
                },
                child: Card(
                  color: widget.selectedItems.contains(data[index])
                      ? Colors.grey
                      : Colors.white,
                  child: Container(
                    child: Row(
                      children: [
                        data[index]['thumbnail'] != null &&
                            data[index]['thumbnail'].isNotEmpty
                            ? Image.network(
                          data[index]['thumbnail'],
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                        )
                            : Container(),
                        Column(
                          children: [
                            Container(
                              width:
                              MediaQuery.of(context).size.width - 150,
                              child: Text(data[index]['title'].toString()),
                            ),
                            Text(data[index]['authors'].toString()),
                            Text(data[index]['sale_price'].toString()),
                            Text(data[index]['status'].toString()),
                          ],
                        ),
                        Icon(
                          widget.selectedItems.contains(data[index])
                              ? Icons.check
                              : null,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            itemCount: data.length,
            controller: _scrollController,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.selectedItems.isNotEmpty) {
            widget.setSelectedItems(widget.selectedItems);
            Navigator.pop(context);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String> getJSONData() async {
    var url = Uri.parse(
        'https://dapi.kakao.com/v3/search/book?target=title&page=$page&query=${_editingController.text}');
    var response = await http.get(url, headers: {
      "Authorization": "KakaoAK fb6430965fa9c29ded41df00c37a3bfa",
    });

    setState(() {
      var dataConvertedToJSON = json.decode(response.body);
      List<dynamic> result = dataConvertedToJSON["documents"];
      data.addAll(result);
    });
    return response.body;
  }
}

class LibraryScreen extends StatelessWidget {
  final List selectedItems;
  final Function setSelectedItems;

  LibraryScreen({required this.selectedItems, required this.setSelectedItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('서재'),
      ),
      body: ListView.builder(
        itemCount: selectedItems.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: ListTile(
              leading: selectedItems[index]['thumbnail'] != null &&
                  selectedItems[index]['thumbnail'].isNotEmpty
                  ? Image.network(selectedItems[index]['thumbnail'])
                  : null,
              title: Text(selectedItems[index]['title']),
              subtitle: Text(selectedItems[index]['authors'].join(', ')),
              onTap: () async {
                var updatedBook = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(book: selectedItems[index]),
                  ),
                );
                if (updatedBook != null) {
                  selectedItems[index] = updatedBook;
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchScreen(selectedItems: selectedItems, setSelectedItems: setSelectedItems),
            ),
          );
        },
        child: Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


class DetailScreen extends StatefulWidget {
  final dynamic book;

  DetailScreen({required this.book});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TextEditingController _memoController = TextEditingController();
  FocusNode _memoFocusNode = FocusNode();

  @override
  void dispose() {
    _memoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book['title']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.book['thumbnail'] != null &&
                widget.book['thumbnail'].isNotEmpty)
              Image.network(widget.book['thumbnail']),
            SizedBox(height: 8.0),
            Text(
              widget.book['title'],
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              widget.book['authors'].join(', '),
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _memoController,
              focusNode: _memoFocusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '문구',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                if (_memoController.text.isNotEmpty) {
                  setState(() {
                    widget.book['memo'] = _memoController.text;
                  });
                }
                _memoFocusNode.unfocus();
              },
              child: Text('문구 남기기'),
            ),
            if (widget.book['memo'] != null)
              Text(
                '문구: ' + widget.book['memo'],
                style: TextStyle(fontSize: 16.0),
              ),
          ],
        ),
      ),
    );
  }
}


class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: Center(
        child: Text('미구현'),
      ),
    );
  }
}
