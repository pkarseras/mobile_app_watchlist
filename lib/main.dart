import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'api_key.dart';
import 'database.dart';

part 'main.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();

  final dao = database.movieDao;

  runApp(MyApp(dao));
}

class MyApp extends StatelessWidget {
  final MovieDao dao;

  const MyApp(this.dao, {super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie watchlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Movie watchlist', dao: dao),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.dao});

  final MovieDao dao;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie watchlist'),
      ),
      body: switch (_selectedIndex) {
        0 => TabDiscover(dao: widget.dao),
        1 => TabWatchlist(dao: widget.dao),
        int() => null,
      },
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigate to...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Discover'),
              onTap: () {
                _selectTab(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Watchlist'),
              onTap: () {
                _selectTab(1);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

@JsonSerializable()
class Movie {
  final bool adult;
  final String? backdrop_path;
  final List<int> genre_ids;
  final int id;
  final String original_language;
  final String original_title;
  final String overview;
  final double popularity;
  final String poster_path;
  final String release_date;
  final String title;
  final bool video;
  final double vote_average;
  final int vote_count;

  Movie(
    this.adult,
    this.backdrop_path,
    this.genre_ids,
    this.id,
    this.original_language,
    this.original_title,
    this.overview,
    this.popularity,
    this.poster_path,
    this.release_date,
    this.title,
    this.video,
    this.vote_average,
    this.vote_count,
  );

  @override
  String toString() => '$title  [$vote_average]';

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  Map<String, dynamic> toJson() => _$MovieToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Movies {
  int page;
  List<Movie> results;
  int total_pages;
  int total_results;

  Movies(this.page, this.results, this.total_pages, this.total_results);

  factory Movies.fromJson(Map<String, dynamic> json) => _$MoviesFromJson(json);

  Map<String, dynamic> toJson() => _$MoviesToJson(this);
}

class TabDiscover extends StatefulWidget {
  final MovieDao dao;

  const TabDiscover({super.key, required this.dao});

  @override
  State<TabDiscover> createState() => _TabDiscoverState();
}

class _TabDiscoverState extends State<TabDiscover> {
  bool _error = false;
  int _page = 1;

  Future<Movies?> _getTMDBPopular(int page) async {
    final String baseUrl = 'https://api.themoviedb.org/3';
    final String popularUrl = '$baseUrl/movie/popular?api_key=$tmdbApiKey&page=$page';

    try {
      http.Response response = await http.get(Uri.parse(popularUrl));
      if (response.statusCode == 200) {
        return Movies.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load popular movies');
      }
    } on Exception {
      setState(() {
        _error = true;
      });
    }
    return null;
  }

  void _next_page() {
    setState(() {
      _page++;
    });
    debugPrint('page: $_page');
  }

  void _previous_page() {
    setState(() {
      _page--;
    });
    debugPrint('page: $_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<Movies?>(
          future: _getTMDBPopular(_page),
          builder: (BuildContext context, AsyncSnapshot<Movies?> snapshot) {
            if (_error) {
              return const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Internet error', style: TextStyle(fontSize: 14, color: Colors.red)),
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 32,
                  )
                ],
              );
            } else if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data!.results.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ExpandableListItemDiscover(
                          title: snapshot.data!.results[index].title,
                          subtitle: 'Score: ${snapshot.data!.results[index].vote_average.toString()}',
                          id: snapshot.data!.results[index].id,
                          dao: widget.dao,
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Align buttons horizontally at the center
                    children: [
                      ElevatedButton(
                        onPressed: (snapshot.data!.page != 1)
                            ? () {
                                _previous_page();
                              }
                            : null,
                        child: Text('Previous'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _next_page();
                        },
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}

class TabWatchlist extends StatefulWidget {
  final MovieDao dao;

  TabWatchlist({super.key, required this.dao});

  List<MovieEntity> watchlist = [];

  @override
  State<StatefulWidget> createState() => _TabWatchlistState();
}

class _TabWatchlistState extends State<TabWatchlist> {
  Future<List<MovieEntity>> _getWatchlist() async {
    var _watchlist = await widget.dao.getAllMovies();
    final List<MovieEntity> movies = [];

    for (var item in _watchlist) {
      movies.add(MovieEntity(item.id, item.title));
    }
    return movies;
  }

  void _loadWatchlist() async {
    var watchlist = await _getWatchlist();
    setState(() {
      widget.watchlist = watchlist;
    });
  }

  @override
  void initState() {
    _loadWatchlist();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          children: [
            for (var a in widget.watchlist)
              ExpandableListItemWatchlist(title: a.title, id: a.id, dao: widget.dao, update_method: _loadWatchlist)
          ],
        ),
      ),
    );
  }
}

// ListView(
// children: snapshot.data!
//     .map((a) =>
// ExpandableListItemWatchlist(
// title: a.title, id: a.id, dao: dao))
//     .toList(),
class ExpandableListItemDiscover extends StatefulWidget {
  final String title;
  final String subtitle;
  final int id;
  final MovieDao dao;

  const ExpandableListItemDiscover(
      {Key? key, required this.title, required this.subtitle, required this.id, required this.dao})
      : super(key: key);

  @override
  _ExpandableListItemDiscoverState createState() => _ExpandableListItemDiscoverState();
}

class _ExpandableListItemDiscoverState extends State<ExpandableListItemDiscover> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final movie_entity = MovieEntity(widget.id, widget.title);
                await widget.dao.insertMovie(movie_entity);
              },
              child: const Text('Add to watchlist'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     // Handle button 2 tap
            //   },
            //   child: const Text('Add to watched'),
            // ),
          ],
        ),
      ],
      onExpansionChanged: (bool expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
    );
  }
}

class ExpandableListItemWatchlist extends StatefulWidget {
  final String title;
  final int id;
  final MovieDao dao;
  late void Function() update_method;

  ExpandableListItemWatchlist(
      {Key? key, required this.title, required this.id, required this.dao, required this.update_method})
      : super(key: key);

  @override
  _ExpandableListItemWatchlistState createState() => _ExpandableListItemWatchlistState();
}

class _ExpandableListItemWatchlistState extends State<ExpandableListItemWatchlist> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.title),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final movie_entity = MovieEntity(widget.id, widget.title);
                await widget.dao.deleteMovie(movie_entity);
                widget.update_method();
              },
              child: const Text('Remove to watchlist'),
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     // Handle button 2 tap
            //   },
            //   child: const Text('Add to watched'),
            // ),
          ],
        ),
      ],
      onExpansionChanged: (bool expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
    );
  }
}
