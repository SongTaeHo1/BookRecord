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
  BottomNavigationState createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> {
  int pageIndex = 0;
  List selectedItemsList = [];

  void setSelectedItems(List items) {
    setState(() {
      selectedItemsList = items;
    });
  }

  final List<Widget> Function(List, Function) screensList = (items, setSelectedItems) => [
    LibraryScreen(selectedItems: items, setSelectedItems: setSelectedItems),
    StatisticsScreen(selectedItems: items),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screensList(selectedItemsList, setSelectedItems)[pageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex,
        onTap: (index) {
          setState(() {
            pageIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '서재',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
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
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  String result = '';
  List<dynamic> data = [];
  TextEditingController editingController = TextEditingController();
  ScrollController scrollController = ScrollController();
  int page = 1;

  @override
  void initState() {
    super.initState();
    editingController.addListener(() {
      if (scrollController.offset >= scrollController.position.maxScrollExtent &&
          !scrollController.position.outOfRange) {
        page++;
        getJSONData();
      }
    });
  }

  @override
  void dispose() {
    editingController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: editingController,
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
            controller: scrollController,
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
        'https://dapi.kakao.com/v3/search/book?target=title&page=$page&query=${editingController.text}');
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
                    builder: (context) => DetailScreen(
                      book: selectedItems[index],
                      onBookStatusChanged: (status) {
                        selectedItems[index]['statusIndex'] = status;
                        setSelectedItems(selectedItems);
                      },
                      statusIndex: selectedItems[index]['statusIndex'],
                    ),
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
  final Function(dynamic) onBookStatusChanged;
  final int statusIndex;

  DetailScreen({required this.book, required this.onBookStatusChanged, int? statusIndex})
      : statusIndex = statusIndex ?? 0;

  @override
  DetailScreenState createState() => DetailScreenState(statusIndex: statusIndex);
}

class DetailScreenState extends State<DetailScreen> {
  TextEditingController memoController = TextEditingController();
  FocusNode memoFocusNode = FocusNode();
  int pageNumber = 0;
  List<String> readingStatus = ['독서중', '읽은책', '읽을책'];
  late int statusIndex;

  DetailScreenState({required this.statusIndex});

  @override
  void initState() {
    super.initState();
    statusIndex = widget.statusIndex ?? 0;
    pageNumber= widget.book['currentPage'] ?? 0;
  }

  @override
  void dispose() {
    memoController.dispose();
    memoFocusNode.dispose();
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
            Text(
              widget.book['contents'],
              style: TextStyle(fontSize: 14.0),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  statusIndex = (statusIndex + 1) % readingStatus.length;
                });
                widget.onBookStatusChanged(statusIndex);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: statusIndex == 0 ? Colors.red : (statusIndex == 1 ? Colors.green : Colors.blue),
              ),
              child: Text('독서 상태: ' + readingStatus[statusIndex]),
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 읽고 있는 페이지: ',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      '$pageNumber 페이지',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('페이지 변경'),
                          content: TextFormField(
                            initialValue: pageNumber.toString(),
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 16.0),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '페이지',
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)  {
                                return '페이지를 입력하세요.';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                pageNumber = int.tryParse(value) ?? 0;
                                widget.book['currentPage'] = pageNumber;
                              });
                            },
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('취소'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('확인'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('독서기록 변경'),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: memoController,
              focusNode: memoFocusNode,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '문구',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                if (memoController.text.isNotEmpty) {
                  setState(() {
                    widget.book['memo'] = memoController.text;
                  });
                }
                memoFocusNode.unfocus();
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

class StatisticsScreen extends StatefulWidget {
  final List selectedItems;

  StatisticsScreen({required this.selectedItems});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  int TabIndex = 0;
  final List<String> readingStatus = ['읽을책', '읽은책'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('통계'),
          bottom: TabBar(
            tabs: [
              Tab(text: readingStatus[0]),
              Tab(text: readingStatus[1]),
            ],
            onTap: (index) {
              setState(() {
                TabIndex = index;
              });
            },
          ),
        ),
        body: TabIndex == 0
            ? BookList(
          selectedItems: widget.selectedItems.where((book) => book['statusIndex'] == 2).toList(),
        )
            : BookList(
          selectedItems: widget.selectedItems.where((book) => book['statusIndex'] == 1).toList(),
        ),
      ),
    );
  }
}

class BookList extends StatelessWidget {
  final List selectedItems;

  BookList({required this.selectedItems});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
          ),
        );
      },
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
      body: ListView(
        children: [
          Card(
            elevation: 2.0,
            child: ListTile(
              title: Text('내정보'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyInfoScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MyInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내정보'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '이름',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '송태호',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '한마디',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '능력부족..',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
