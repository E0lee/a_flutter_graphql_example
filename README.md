# a_flutter_graphql_example

a_flutter_graphql_example.

### 前情提要
面試又被問到了，我根本沒用過這個啊，只好稍微摸摸了，起碼面試的f候可以瞎逼逼幾句。
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
![image](https://hackmd.io/_uploads/BkPVxpB_T.png)
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
    child: MyApp(),
  ));
}
class MyApp extends StatelessWidget {
  MyApp({super.key});

  String query =
      """query { 
  Media (id: 15125, type: ANIME) { 
    id
    title {
      romaji
      english
      native
    }
  }
}""";
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

範例專案檔在這
https://github.com/E0lee/a_flutter_graphql_example