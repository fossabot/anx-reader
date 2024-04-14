import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';

import '../models/toc_item.dart';
import '../utils/generate_index_html.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Book _book;
  String? _content;
  BookStyle _bookStyle = BookStyle();
  bool _isAppBarVisible = false;
  double _appBarTopPosition = -kToolbarHeight;
  double readProgress = 0.0;
  List<TocItem> _tocItems = [];
  Widget _currentPage = const SizedBox(height: 1);
  Timer? _sliderTimer;
  final _epubPlayerKey = GlobalKey<EpubPlayerState>();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    loadContent();
  }

  void loadContent() {
    var content = generateIndexHtml(
        widget.book, _bookStyle, widget.book.lastReadPosition);
    setState(() {
      _content = content;
    });
  }

  void showOrHideAppBarAndBottomBar(bool show) {
    setState(() {
      if (show) {
        if (_isAppBarVisible) {
          show = false;
        }
        _appBarTopPosition = 0;
      } else {
        _appBarTopPosition = -kToolbarHeight;
      }
      _isAppBarVisible = show;
    });
  }

  void onReadProgressChanged(double value) {
    setState(() {
      readProgress = value;
    });
  }

  Future<void> tocHandler() async {
    String toc = await _epubPlayerKey.currentState!.getToc();
    setState(() {
      _tocItems =
          (json.decode(toc) as List).map((i) => TocItem.fromJson(i)).toList();
      _currentPage = TocWidget(
          tocItems: _tocItems,
          epubPlayerKey: _epubPlayerKey,
          hideAppBarAndBottomBar: showOrHideAppBarAndBottomBar);
    });
  }

  void noteHandler() {
    setState(() {
      _currentPage = Container(
        height: 700,
      );
    });
  }

  Future<void> progressHandler() async {
    readProgress = _epubPlayerKey.currentState!.progress;
    print(readProgress);
    setState(() {
      _currentPage = Container(
        height: 700,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          String cfi = await _epubPlayerKey.currentState!.onReadingLocation();
          Navigator.pop(context, cfi);
        },
        child: Scaffold(
          body: Stack(
            children: [
              EpubPlayer(
                key: _epubPlayerKey,
                content: _content!,
                showOrHideAppBarAndBottomBar: showOrHideAppBarAndBottomBar,
              ),
              if (_isAppBarVisible)
                AnimatedPositioned(
                  top: _appBarTopPosition,
                  left: 0,
                  right: 0,
                  duration: const Duration(milliseconds: 3000),
                  child: AppBar(
                    title: Text(_book.title),
                  ),
                ),
              if (_isAppBarVisible)
                AnimatedPositioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  duration: const Duration(milliseconds: 3000),
                  // child: BottomAppBar(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Wrap(
                      children: [
                        // TocWidget(tocItems: tocItems),
                        // _currentPage,
                        Container(
                            height: 300,
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  _epubPlayerKey.currentState!.chapterTitle,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'SourceHanSerif',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: () {
                                        _epubPlayerKey.currentState!
                                            .prevChapter();
                                      },
                                    ),
                                    Expanded(
                                      child: Slider(
                                          inactiveColor: Colors.grey.shade300,
                                          value: readProgress,
                                          onChanged: (value) {
                                            setState(() {
                                              readProgress = value;
                                            });
                                            _sliderTimer?.cancel();
                                            _sliderTimer = Timer(
                                                const Duration(
                                                    milliseconds: 300), () {
                                              _epubPlayerKey.currentState!
                                                  .goToPersentage(value);
                                            });
                                          }),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward),
                                      onPressed: () {
                                        _epubPlayerKey.currentState!
                                            .nextChapter();
                                      },
                                    ),
                                  ],
                                )
                              ],
                            )),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.toc),
                              onPressed: () {
                                tocHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () {
                                noteHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.data_usage),
                              onPressed: () {
                                progressHandler();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.color_lens),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.text_fields),
                              onPressed: () {
                                // _epubPlayerKey.currentState!.nextPage();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
  }
}

class TocWidget extends StatelessWidget {
  const TocWidget({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final epubPlayerKey;
  final hideAppBarAndBottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 700,
        child: ListView.builder(
          itemCount: tocItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(tocItems[index].label),
              onTap: () {
                hideAppBarAndBottomBar(false);
                epubPlayerKey.currentState!.goTo(tocItems[index].href);
              },
            );
          },
        ));
  }
}
