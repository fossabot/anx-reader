import '../models/book.dart';
import '../models/book_style.dart';
import '../service/book_player/book_player_server.dart';

String generateIndexHtml(Book book, BookStyle style, String cfi) {
  String bookPath = 'http://localhost:${Server().port}/book/${book.filePath}';
  return '''
  <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Anx Reader</title>

      <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.5/jszip.min.js"></script>

      <script src="https://cdn.jsdelivr.net/npm/epubjs/dist/epub.min.js"></script>

      <style>
        body {
          margin: 0;
          padding: 0;
          overflow: hidden;
        }
      </style>
    </head>
<body>
  <div id="viewer"></div>

  <script>
    var book = ePub("$bookPath")
    var rendition = book.renderTo("viewer", {
        width: window.innerWidth,
        height: window.innerHeight,
    })
    
    book.ready.then(function() {
        return book.locations.generate(500); 
    });
    
    getCurrentChapterTitle = function() {
      let toc = book.navigation.toc;
      let href = rendition.currentLocation().start.href;
      let chapter = toc.filter(chapter => chapter.href === href)[0];
      console.log(chapter.label);
      return chapter.label.trim(); 
    }
    
    refreshProgress = function() {
      var progress = book.locations.percentageFromCfi(rendition.currentLocation().start.cfi);
      window.flutter_inappwebview.callHandler('getProgress', progress);
      window.flutter_inappwebview.callHandler('getChapterCurrentPage', rendition.location.start.displayed.page);
      window.flutter_inappwebview.callHandler('getChapterTotalPage', rendition.location.end.displayed.total);
      window.flutter_inappwebview.callHandler('getChapterTitle', getCurrentChapterTitle());
    }

    var renderBook = async function() {
      if ('$cfi' !== '') {
        await rendition.display('$cfi')
      } else {
        await rendition.display()
      }

      rendition.on('relocated', function(locations) {
        refreshProgress();
      });
    };
    renderBook()
  </script>
</body>

    </html>
  ''';
}