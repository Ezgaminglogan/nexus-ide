import 'model.dart';
import 'tracks/arduino.dart';
import 'tracks/c.dart';
import 'tracks/csharp.dart';
import 'tracks/java.dart';
import 'tracks/php.dart';
import 'tracks/python.dart';
import 'tracks/raspi.dart';
import 'tracks/web.dart';

/// Every Learn track, in home-screen order. Add a track: write `lib/learn/tracks/<id>.dart` and list it here.
const tracks = <Track>[cTrack, pythonTrack, javaTrack, csharpTrack, phpTrack, raspiTrack, arduinoTrack, webTrack];

Track? trackFor(String langId) => tracks.where((t) => t.langId == langId).firstOrNull;
