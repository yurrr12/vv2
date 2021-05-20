import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart' show rootBundle;

class Dbs {
  static Future<Database> database;
  Future<String> getFileData(String path) async {
    return await rootBundle.loadString(path);
  }
  void loadSongs() async{
    String read = await getFileData("assets/songs_init.txt");
    List<String> readIn = read.split('\n');
    for(int i=0;i<readIn.length;i++){
      List<String> readOne = readIn[i].split('*');
      String newLast = "";
      for(int j=0;j<readOne[readOne.length-1].length;j++){
        if(readOne[readOne.length-1][j] == '\r')
        break;
        newLast += readOne[readOne.length-1][j];
      }
      readOne[readOne.length-1] = newLast;
      String artists = readOne[0].split('-')[0];
      String names = readOne[0].split('-')[1];
      print(i.toString()+": " + artists +" and " + names);
      insertSongs(new Song(id: i, name: names, artist: artists, urlSong: readOne[1], urlPic: readOne[2], category: readOne[3]));
    }
  }
  void initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    database = openDatabase(
      join(await getDatabasesPath(), 'myfm_database.db'),
      onCreate: (db, version) {
        db.execute("CREATE TABLE customers(id INTEGER PRIMARY KEY, name TEXT, password TEXT, lastListened TEXT, liked TEXT, history TEXT)");
        db.execute('CREATE TABLE songs(id INTEGER PRIMARY KEY, name TEXT, artist TEXT, urlSong TEXT, urlPic TEXT, category TEXT)');
      },
      version: 1,
    );
    if(await songs() == null)
      loadSongs();
    print(await songs());
  }
  Future<void> insertSongs(Song song) async {
    final Database db = await database;
    await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //print(await songs());
  }
  Future<void> insertSongsCategory(SongCategory songCategory) async {
    final Database db = await database;
    await db.insert(
      'songCategory',
      songCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<void> insertCustomer(Customer customer) async {
    final Database db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    //print(await customers());
  }
  Future<List<Customer>> customers() async {
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('customers');
      return List.generate(maps.length, (i) {
        return Customer(
          id: maps[i]['id'],
          name: maps[i]['name'],
          password: maps[i]['password'],
          lastListened: maps[i]['lastListened'],
          liked: maps[i]['liked'],
          history: maps[i]['history']
        );
      });
    }
  Future<List<Song>> songs() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    if(maps.length < 1)
      return null;
    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        name: maps[i]['name'],
        artist: maps[i]['artist'],
        urlSong: maps[i]['urlSong'],
        urlPic: maps[i]['urlPic'],
        category: maps[i]['category'],
      );
    });
  }
  Future<Customer>  findCustomer(String username) async{
    List<Customer> cs = await customers();
    for(int i = 0;i < cs.length;i++)
      if(cs[i].name ==  username)
        return cs[i];
    return null;
  }
    Future<Customer> loginCustomer(String name, String password) async {
        List<Customer> cs = await customers();
        for(int i = 0;i < cs.length;i++){
          if(cs[i].name == name && cs[i].password == password)
            return cs[i];
        }
        return null;
    }
  void updateCustomerLiked(Customer customer, String liked) async {
    final Database db = await database;
    List<Customer> cs = await customers();
    customer.liked = liked;
    await db.update(
      'customers',
      customer.toMap(),
      where: "id = ?",
      whereArgs: [customer.id],
    );
  }
  void updateCustomerHistory(Customer customer, String history) async {
    final Database db = await database;
    List<Customer> cs = await customers();
    customer.history = history;
    await db.update(
      'customers',
      customer.toMap(),
      where: "id = ?",
      whereArgs: [customer.id],
    );
  }
  void updateCustomerLastListened(Customer customer, String lastListened) async {
    final Database db = await database;
    List<Customer> cs = await customers();
    customer.lastListened = lastListened;
    await db.update(
      'customers',
      customer.toMap(),
      where: "id = ?",
      whereArgs: [customer.id],
    );
  }
    void updateCustomer(Customer customer, String name, String password) async {
      final Database db = await database;
      List<Customer> cs = await customers();
      customer.name = name;
      customer.password = password;
      await db.update(
        'customers',
        customer.toMap(),
        where: "id = ?",
        whereArgs: [customer.id],
      );
    }
    Future<void> deleteCustomer(int id) async {
      final db = await database;
      await db.delete(
        'customers',
        where: "id = ?",
        whereArgs: [id],
      );
    }
    Future<int> getId() async{
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('customers');
      List<Map> result = await db.query('customers');
      return result.length + 1;
    }
    Future<int> getSongId() async{
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('songs');
      List<Map> result = await db.query('songs');
      return result.length + 1;
    }
  }
class Customer {
  final int id;
  String name, password, lastListened, liked, history;
  Customer({this.id, this.name, this.password, this.lastListened, this.liked, this.history});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'lastListened': lastListened,
      'liked': liked,
      'history': history,
    };
  }
  @override
  String toString() {
    return 'Customer{id: $id, name: $name, password: $password, liked: $liked, history: $history}';
  }
}
class SongCategory {
  int id;
  int occurrence;
  String name;
  SongCategory(int id, String name, int occurrence){
    this.id = id;
    this.name = name;
    this.occurrence = occurrence;
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'occurrence': occurrence,
    };
  }
}
class Song{
  final int id;
  String name, artist, urlSong, urlPic, category;
  Song({this.id, this.name, this.artist, this.urlSong, this.urlPic, this.category});
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'urlSong': urlSong,
      'urlPic': urlPic,
      'category': category,
    };
  }
  @override
  String toString() {
    return 'Song{id: $id, name: , artist: $artist, $name, category: $category, urlSong: $urlSong}';
  }
}