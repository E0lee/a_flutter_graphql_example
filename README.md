# a_flutter_graphql_example

a_flutter_graphql_example.

### 前情提要
面試又被問到了，我根本沒用過這個啊，只好稍微摸摸了，起碼面試的時候可以瞎逼逼幾句。
剛好面的又是flutter，所以決定用fluter來接。

### 請教
根據年薪百萬室友的說法，GraphQL可以處理Restful N+1的問題，蛤，啥N+1我聽都沒聽過。

> N+1 问题的基本情况
"N" 指的是什么:
>
>假设有一个数据实体（比如“用户”），你需要获取与每个用户相关联的另一个实体（比如“订单”）的数据。如果有 N 个用户，那么首先会发出一个请求来获取所有用户的列表。
再加上 "1":
>
>接着，对于列表中的每个用户（N个），你需要发出另一个请求来获取他们各自的订单信息。这意味着总共需要发送 N + 1 个请求：1 个请求获取所有用户，N 个请求分别获取每个用户的订单。
N+1 问题的影响
性能问题:
>
>这导致了大量的 HTTP 请求，增加了服务器负载，也增加了客户端处理这些请求的时间。
低效的数据获取:
>
>发送大量请求通常比发送单个或少数几个请求效率低下，特别是在网络延迟较高的情况下。
>By ChatGpt4

好，懂了，雖然Restful也可以改善這個問題，但體質上來講GraphQL會比較有效。

### 開始實作
#### 準備一個對接API
因為練習的目標是接API，所以API就是找一個現成的囉。
https://github.com/graphql-kit/graphql-apis?tab=readme-ov-file
> 謝謝大大無私的分享

選自己喜歡的囉，我選第一個看起來是搜索動畫的api
點try it試試看，一開始還真的不知道打什麼，所以去翻了一下Doc，找到了範例。
```
{
  Media(id: 15125) {
    id
    title {
      romaji
      native
    }
  }
}
```
成功要到資料！
這樣當作api可以被使用了
#### 尋找flutter plugin
沒啥好說的，先找第一個就對了
https://pub.dev/packages/graphql_flutter

#### 照著教學做

總之先開個專案...
```dart
Future<void> main() async {
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink(
    'https://graphql.anilist.co/',
  );

  final Link link = httpLink.concat(httpLink);

  ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(GraphQLProvider(
    client: client,
    child: Demo1(),
  ));
}

class Demo1 extends StatelessWidget {
  Demo1({super.key});

  String query = """query {
  Media (id: 15125, type: ANIME) {
    id
    title {
      romaji
      english
      native
    }
  }
}""";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("graphql demo"),
        ),
        body: Center(
            child: Query(
          options: QueryOptions(document: gql(query)),
          builder: (QueryResult result,
              {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }
            if (result.isLoading) {
              return const Text('Loading');
            }
            return Text(result.data!['Media']['title']['native'].toString());
          },
        )),
      ),
    );
  }
}
```
啪 好了，這個就是最簡單的範例了，收工！

## 誒，等等
來試試一些變化題型
#### 加入變數id
畢竟要做查詢還是得把變數加進去

```dart
class Demo2 extends StatelessWidget {
  Demo2({super.key});

  String query = """query GetMedia(\$id: Int!){
  Media (id: \$id, type: ANIME) {
    id
    title {
      romaji
      english
      native
    }
  }
}""";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final int mediaId = 15125;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("graphql demo"),
        ),
        body: Center(
            child: Query(
          options: QueryOptions(
            document: gql(query),
            variables: {'id': mediaId},
          ),
          builder: (QueryResult result,
              {VoidCallback? refetch, FetchMore? fetchMore}) {
            if (result.hasException) {
              return Text(result.exception.toString());
            }
            if (result.isLoading) {
              return const Text('Loading');
            }
            return Text(result.data!['Media']['title']['native'].toString());
          },
        )),
      ),
    );
  }
}
```
這次做的事情有：
* 使用variables帶id變數進去

#### 試試看paging
由前面提到的N+1改善優勢，graphql可以一次取得所有的anime資料，雖然減少了請求的次數，但資料量就會很大，這邊就會讓paging派上用場，簡單講就是類似sql的limit，由於資料量還是很大，就加上了該API本來就有的serch功能縮小查詢範圍。
```
query  {
  Page (page: 1, perPage: 5) {
    pageInfo {
      total
      currentPage
      lastPage
      hasNextPage
      perPage
    }
    media (type: ANIME search: "Fate/Zero") {
      id
      title {
        romaji
        native
      }
    }
  }
}
```
開始實作
```dart
@override
Widget build(BuildContext context) {
final int perPage = 3;

return MaterialApp(
  title: 'Flutter Demo3',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,
  ),
  home: Scaffold(
    appBar: AppBar(
      title: Text("graphql demo"),
    ),
    body: Center(
        child: Query(
      options: QueryOptions(
        document: gql(query),
        variables: {
          'page': 1,
          'perPage': perPage,
        },
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.hasException) {
          return Text(result.exception.toString());
        }
        if (result.isLoading) {
          return const Text('Loading');
        }

        //先知道有沒有下一頁
        bool hasNextPage = result.data!['Page']['pageInfo']['hasNextPage'];
        int currentPage = result.data!['Page']['pageInfo']['currentPage'];

        if (hasNextPage) {
          //呼叫更多資料
          FetchMoreOptions options = FetchMoreOptions(
            variables: {'page': currentPage + 1, 'perPage': perPage},
            updateQuery: (previousResultData, fetchMoreResultData) {
              // 把前一次的搜尋結果跟下次的搜尋結果整合再一起
              final List<dynamic> repos = [
                ...previousResultData!['Page']['media'] as List<dynamic>,
                ...fetchMoreResultData!['Page']['media'] as List<dynamic>
              ];
              fetchMoreResultData!['Page']['media'] = repos;

              return fetchMoreResultData;
            },
          );
          fetchMore!(options);
        }

        List mediaList = result.data!['Page']['media'];
        return ListView.builder(
          itemCount: mediaList.length,
          itemBuilder: (context, index) {
            var media = mediaList[index];
            return ListTile(
              title: Text(media['title']['romaji']),
              subtitle: Text(media['title']['native']),
            );
          },
        );
      },
    )),
  ),
);
}
```
這次做的事情有：
* 把query結果分成3頁，先抓第一頁
* 確定有沒有下一頁，用FetchMoreOptions抓後續資料
* 用ListView顯示資料

範例專案檔在這
https://github.com/E0lee/a_flutter_graphql_example