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
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

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
