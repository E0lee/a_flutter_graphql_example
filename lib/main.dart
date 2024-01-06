import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
    child: Demo3(),
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
          title: Text("graphql demo1"),
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
      title: 'Flutter Demo2',
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

class Demo3 extends StatelessWidget {
  Demo3({super.key});

  String query = """
  query GetMedia(\$page: Int!, \$perPage: Int!) {
    Page(page: \$page, perPage: \$perPage) {
      pageInfo {
        total
        currentPage
        lastPage
        hasNextPage
        perPage
      }
      media (type: ANIME, search: "Fate/Zero") {
        id
        title {
          romaji
          native
        }
      }
    }
  }
""";
  // This widget is the root of your application.
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
}
