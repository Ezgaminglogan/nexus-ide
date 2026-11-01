import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// A 3D Raspberry Pi 3 you can turn and zoom, with the simulator's live pins on its real 40-pin
/// header. Drawn by Flutter itself (no WebView), so it works offline on Windows and phones.
///
/// Model: "Raspberry Pi 3" by JoSaCo (https://sketchfab.com/3d-models/raspberry-pi-3-2d308283fc0f4d27b81f17a2793c5c4d),
/// licensed CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Not changed, only displayed.
const piModelCredit = '3D model "Raspberry Pi 3" by JoSaCo (Sketchfab), CC BY 4.0';

/// The model, read once from the bundled .glb: the textured board (mesh 0) and a small plain part (mesh 2).
class PiModel {
  PiModel._(this.pos, this.norm, this.uv, this.idx, this.plainPos, this.plainIdx, this.texture);
  final Float32List pos, norm, uv, plainPos; // xyz per vertex (model is Z-up), uv in texture pixels
  final Uint16List idx, plainIdx; // triangles
  final ui.Image texture;

  static Future<PiModel>? _loading;
  static Future<PiModel> load() => _loading ??= _read();

  static Future<PiModel> _read() async {
    final data = await rootBundle.load('assets/raspi/raspberry_pi_3.glb');
    final b = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
    final jsonLen = b.getUint32(12, Endian.little);
    final gltf = jsonDecode(utf8.decode(data.buffer.asUint8List(data.offsetInBytes + 20, jsonLen))) as Map<String, dynamic>;
    final binStart = data.offsetInBytes + 20 + jsonLen + 8;
    final views = (gltf['bufferViews'] as List).cast<Map<String, dynamic>>();
    final accessors = (gltf['accessors'] as List).cast<Map<String, dynamic>>();

    Uint8List view(int i) {
      final v = views[i];
      return data.buffer.asUint8List(binStart + (v['byteOffset'] as int? ?? 0), v['byteLength'] as int);
    }

    // Copies, so the arrays are aligned and independent of the asset buffer.
    Float32List floats(int a) {
      final acc = accessors[a], n = {'VEC2': 2, 'VEC3': 3}[acc['type']]! * (acc['count'] as int);
      final bytes = view(acc['bufferView'] as int);
      return Float32List.fromList(bytes.buffer.asFloat32List(bytes.offsetInBytes + (acc['byteOffset'] as int? ?? 0), n));
    }

    Uint16List indices(int a) {
      final acc = accessors[a], bytes = view(acc['bufferView'] as int);
      return Uint16List.fromList(bytes.buffer.asUint32List(bytes.offsetInBytes + (acc['byteOffset'] as int? ?? 0), acc['count'] as int));
    }

    final meshes = (gltf['meshes'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic> prim(int m) => ((meshes[m]['primitives'] as List).first as Map<String, dynamic>);
    final board = prim(0), plain = prim(2);
    final attrs = (board['attributes'] as Map).cast<String, int>();
    final image = (gltf['images'] as List).first as Map<String, dynamic>;
    final codec = await ui.instantiateImageCodec(view(image['bufferView'] as int));
    final texture = (await codec.getNextFrame()).image;
    final uv = floats(attrs['TEXCOORD_0']!);
    for (var i = 0; i < uv.length; i += 2) {
      uv[i] *= texture.width;
      uv[i + 1] *= texture.height;
    }
    return PiModel._(
      floats(attrs['POSITION']!),
      floats(attrs['NORMAL']!),
      uv,
      indices(board['indices'] as int),
      floats((plain['attributes'] as Map)['POSITION'] as int),
      indices(plain['indices'] as int),
      texture,
    );
  }
}

/// Where the 40-pin header's pin tips are on this model (measured from the mesh: 20 columns
/// 2.54 mm apart, pin 1 at the end away from the USB ports, odd pins on the inner row).
Float64List piPinPosition(int physical) {
  final col = (physical - 1) ~/ 2;
  return Float64List.fromList([-3.300 + col * 0.2443, physical.isOdd ? 2.228 : 2.464, 0.583]);
}

/// How the board is turned: yaw spins it flat on the table, pitch tilts it toward you.
class PiCamera {
  PiCamera(this.yaw, this.pitch, this.zoom, this.size);
  final double yaw, pitch, zoom;
  final Size size;
  static const _center = [0.045, -0.144, 0.45]; // middle of the model
  double get scale => math.min(size.width / 8.6, size.height / 6.0) * zoom;

  /// Screen position and depth (bigger = nearer) of a model point.
  (Offset, double) project(double x, double y, double z) {
    final px = x - _center[0], py = y - _center[1], pz = z - _center[2];
    final cy = math.cos(yaw), sy = math.sin(yaw), cp = math.cos(pitch), sp = math.sin(pitch);
    final x1 = px * cy - py * sy, y1 = px * sy + py * cy;
    final y2 = y1 * cp - pz * sp, z2 = y1 * sp + pz * cp;
    return (Offset(size.width / 2 + x1 * scale, size.height / 2 - y2 * scale), z2);
  }

  /// True when the board's top (where the header is) faces the viewer.
  bool get topVisible => math.cos(pitch) > 0.05;
}

class _PiPainter extends CustomPainter {
  _PiPainter(this.model, this.yaw, this.pitch, this.zoom);
  final PiModel model;
  final double yaw, pitch, zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final cam = PiCamera(yaw, pitch, zoom, size);
    final cy = math.cos(yaw), sy = math.sin(yaw), cp = math.cos(pitch), sp = math.sin(pitch);

    // The small plain part first, in its own colour.
    final plainXY = Float32List(model.plainPos.length ~/ 3 * 2);
    for (var i = 0, j = 0; i < model.plainPos.length; i += 3, j += 2) {
      final (o, _) = cam.project(model.plainPos[i], model.plainPos[i + 1], model.plainPos[i + 2]);
      plainXY[j] = o.dx;
      plainXY[j + 1] = o.dy;
    }
    canvas.drawVertices(ui.Vertices.raw(VertexMode.triangles, plainXY, indices: model.plainIdx), BlendMode.src, Paint()..color = const Color(0xFF1C5A3A));

    // The textured board: project every vertex, shade it by how much it faces you, then draw the
    // triangles far to near (painter's algorithm: no depth buffer needed).
    final n = model.pos.length ~/ 3;
    final xy = Float32List(n * 2), depth = Float32List(n), colors = Int32List(n);
    for (var v = 0; v < n; v++) {
      final (o, d) = cam.project(model.pos[v * 3], model.pos[v * 3 + 1], model.pos[v * 3 + 2]);
      xy[v * 2] = o.dx;
      xy[v * 2 + 1] = o.dy;
      depth[v] = d;
      final nx = model.norm[v * 3], ny = model.norm[v * 3 + 1], nz = model.norm[v * 3 + 2];
      final light = ((nx * sy + ny * cy) * sp + nz * cp).abs(); // the turned normal's part toward the viewer (double-sided)
      final g = (110 + 145 * light.clamp(0.0, 1.0)).round();
      colors[v] = 0xFF000000 | g << 16 | g << 8 | g;
    }
    final tris = model.idx.length ~/ 3;
    final order = List<int>.generate(tris, (t) => t);
    final key = Float32List(tris);
    for (var t = 0; t < tris; t++) {
      key[t] = depth[model.idx[t * 3]] + depth[model.idx[t * 3 + 1]] + depth[model.idx[t * 3 + 2]];
    }
    order.sort((a, b) => key[a].compareTo(key[b]));
    final sorted = Uint16List(model.idx.length);
    for (var i = 0; i < tris; i++) {
      final t = order[i];
      sorted[i * 3] = model.idx[t * 3];
      sorted[i * 3 + 1] = model.idx[t * 3 + 1];
      sorted[i * 3 + 2] = model.idx[t * 3 + 2];
    }
    canvas.drawVertices(
      ui.Vertices.raw(VertexMode.triangles, xy, textureCoordinates: model.uv, colors: colors, indices: sorted),
      BlendMode.modulate,
      Paint()..shader = ImageShader(model.texture, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage, filterQuality: FilterQuality.medium),
    );
  }

  @override
  bool shouldRepaint(_PiPainter old) => old.yaw != yaw || old.pitch != pitch || old.zoom != zoom || old.model != model;
}

/// The 3D board with the live pins: [pin] builds the widget for one header pin (the same pins
/// as the flat panel: colour from the program, hold an input pin to press it).
class Pi3DBoard extends StatefulWidget {
  const Pi3DBoard({super.key, required this.pin});
  final Widget Function(int physical, double size) pin;

  @override
  State<Pi3DBoard> createState() => _Pi3DBoardState();
}

class _Pi3DBoardState extends State<Pi3DBoard> {
  static const _yaw0 = 0.0, _pitch0 = -0.75, _zoom0 = 1.0;
  double _yaw = _yaw0, _pitch = _pitch0, _zoom = _zoom0, _zoomAtStart = 1;
  final _model = PiModel.load();

  void _reset() => setState(() {
    _yaw = _yaw0;
    _pitch = _pitch0;
    _zoom = _zoom0;
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _model,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('Could not load the 3D board: ${snap.error}', style: const TextStyle(color: Nx.muted)),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final cam = PiCamera(_yaw, _pitch, _zoom, size);
            final dot = (cam.scale * 0.2).clamp(6.0, 26.0);
            return Listener(
              onPointerSignal: (e) {
                if (e is PointerScrollEvent) setState(() => _zoom = (_zoom * (e.scrollDelta.dy > 0 ? 0.9 : 1.1)).clamp(0.6, 4.0));
              },
              child: GestureDetector(
                key: const Key('pi3d'),
                behavior: HitTestBehavior.opaque,
                onDoubleTap: _reset,
                onScaleStart: (_) => _zoomAtStart = _zoom,
                onScaleUpdate: (d) => setState(() {
                  if (d.pointerCount > 1) _zoom = (_zoomAtStart * d.scale).clamp(0.6, 4.0);
                  _yaw += d.focalPointDelta.dx * 0.01;
                  _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(-math.pi, math.pi);
                }),
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _PiPainter(snap.data!, _yaw, _pitch, _zoom))),
                    // The live pins sit on the model's header while its top faces you.
                    if (cam.topVisible)
                      for (var i = 1; i <= 40; i++)
                        Builder(
                          builder: (context) {
                            final p = piPinPosition(i);
                            final (o, _) = cam.project(p[0], p[1], p[2]);
                            return Positioned(left: o.dx - dot / 2, top: o.dy - dot / 2, width: dot, height: dot, child: widget.pin(i, dot));
                          },
                        ),
                    Positioned(
                      right: 4,
                      top: 0,
                      child: IconButton(
                        tooltip: 'Reset the view',
                        visualDensity: VisualDensity.compact,
                        onPressed: _reset,
                        icon: const Icon(Icons.threed_rotation, size: 18, color: Nx.muted),
                      ),
                    ),
                    const Positioned(
                      left: 6,
                      bottom: 2,
                      child: Text(piModelCredit, style: TextStyle(fontSize: 9.5, color: Nx.muted)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
