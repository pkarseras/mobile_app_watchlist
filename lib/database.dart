import 'dart:async';

import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'database.g.dart'; // the generated code will be there

@entity
class MovieEntity {
  @primaryKey
  final int id;
  final String title;

  MovieEntity(this.id, this.title);
}

@dao
abstract class MovieDao {
  @Query('SELECT * FROM MovieEntity')
  Future<List<MovieEntity>> getAllMovies();

  @insert
  Future<void> insertMovie(MovieEntity movie);

  @delete
  Future<void> deleteMovie(MovieEntity movie);
}


@Database(version: 1, entities: [MovieEntity])
abstract class AppDatabase extends FloorDatabase {
  MovieDao get movieDao;
}
