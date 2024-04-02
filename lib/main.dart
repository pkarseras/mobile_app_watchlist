import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'api_key.dart';

part 'main.g.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie watchlist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Movie watchlist'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    Discover(),
    const TabScreen(title: 'Tab 2'),
    const TabScreen(title: 'Tab 3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie watchlist'),
      ),
      body: _tabs[_selectedIndex],
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
            ListTile(
              title: const Text('Watched'),
              onTap: () {
                _selectTab(2);
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
  final String backdrop_path;
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

class Discover extends StatelessWidget {
  Future<List<Movie>> _getTMDBPopular() async {
    final String baseUrl = 'https://api.themoviedb.org/3';
    final String popularUrl = '$baseUrl/movie/popular?api_key=$tmdbApiKey';

    http.Response response = await http.get(Uri.parse(popularUrl));

    if (response.statusCode == 200) {
      return Movies.fromJson(jsonDecode(response.body)).results;
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<List<Movie>>(
          future: _getTMDBPopular(),
          builder: (BuildContext context, AsyncSnapshot<List<Movie>> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            } else {
              if (snapshot.hasData) {
                return ListView(
                  children: snapshot.data!
                      .map((a) => ListTile(title: Text(a.title), subtitle: Text('Score: ${a.vote_average.toString()}')))
                      .toList(),
                );
              }
              return Container();
            }
          },
        ),
      ),
    );
  }
}

class TabScreen extends StatelessWidget {
  final String title;

  const TabScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
//
// class ExpandableListItem extends StatefulWidget {
//   final String title;
//
//   const ExpandableListItem({Key? key, required this.title}) : super(key: key);
//
//   @override
//   _ExpandableListItemState createState() => _ExpandableListItemState();
// }
//
// class _ExpandableListItemState extends State<ExpandableListItem> {
//   bool _isExpanded = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return ExpansionTile(
//       title: Text(widget.title),
//       children: <Widget>[
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             ElevatedButton(
//               onPressed: () {
//                 // Handle button 1 tap
//               },
//               child: Text('Button 1'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 // Handle button 2 tap
//               },
//               child: Text('Button 2'),
//             ),
//           ],
//         ),
//       ],
//       onExpansionChanged: (bool expanded) {
//         setState(() {
//           _isExpanded = expanded;
//         });
//       },
//     );
//   }
// }
