import 'package:mongo_dart/mongo_dart.dart';

class MongoDB {
  String connString = 'mongodb://localhost:27017/snow_migration';
  Db db;
  Future<bool> initDB() async {
    db = Db(connString);
    await db.open();
    await db.close();
    return true;
  }

  Future<void> createRecord(url, json, status, dur, proc) async {
    db = Db(connString);
    await db.open();
    await db.collection('snow_migration').insert({
      'url': url,
      'json': json,
      'status': status,
      'duration': dur,
      'Process': proc
    });
    await db.close();
  }
}
