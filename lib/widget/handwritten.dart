import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class Handwritten extends StatefulWidget {
  const Handwritten({
    Key? key,
    this.initImgPath,
    this.onTapClearImage,
  }) : super(key: key);

  final String? initImgPath;
  final GestureTapCallback? onTapClearImage;

  @override
  HandwrittenState createState() => HandwrittenState();
}

class HandwrittenState extends State<Handwritten> {
  final GlobalKey _captureKey = GlobalKey();
  List<Path> _paths = <Path>[];
  List<Path> _futurePaths = <Path>[];
  Path _path = Path();
  bool _repaint = false;
  String? _imgPath;

  @override
  void initState() {
    _paths = [];
    _imgPath = widget.initImgPath ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final handwritten = GestureDetector(
      onPanDown: (DragDownDetails details) {
        print("down");
        _panDown(details);
      },
      onPanUpdate: (DragUpdateDetails details) {
        print("update");
        _panUpdate(details);
      },
      onPanEnd: (DragEndDetails details) {
        print("end");
        _panEnd(details);
      },
      child: ClipRect(
        child: CustomPaint(
          painter: _HandwritingPainter(
            paths: _paths,
            repaint: _repaint,
          ),
          size: Size.infinite,
        ),
      ),
    );
    final imageHandwritten = Image.file(
      File(_imgPath!),
      fit: BoxFit.fill,
    );

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: RepaintBoundary(
              key: _captureKey,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _imgPath!.isEmpty ? handwritten : imageHandwritten,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeIn,
          child: _imgPath!.isEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildBtnAction(
                      Icons.undo,
                      onTap: () => _backClick(),
                    ),
                    const SizedBox(width: 8),
                    _buildBtnAction(
                      Icons.redo,
                      onTap: () => _forwardClick(),
                    ),
                    const SizedBox(width: 8),
                    _buildBtnAction(
                      Icons.close,
                      onTap: () => _clearClick(),
                    ),
                  ],
                )
              : _buildBtnAction(
                  Icons.close,
                  onTap: () => _clearClick(),
                ),
        ),
      ],
    );
  }

  Widget _buildBtnAction(
    IconData icon, {
    required GestureTapCallback onTap,
  }) {
    return Material(
      color: Colors.grey,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.green[100],
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.all(8 / 2),
          child: Icon(
            icon,
            size: 16,
          ),
        ),
      ),
    );
  }

  Future<File?> captureHandwrittenWidget() async {
    if (_paths.isEmpty) {
      return null;
    }

    final RenderRepaintBoundary boundary =
        _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage();

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      return null;
    }
    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // get app_cache path
    final appDocDir = await getApplicationDocumentsDirectory();
    final appCacheDir =
        await Directory('${appDocDir.path}/app_cache').create(recursive: true);

    // Write file
    final path = "${appCacheDir.path}/handwritten.png";
    File(path).writeAsBytesSync(pngBytes);

    return File(path);
  }

  _panDown(DragDownDetails details) {
    // update status repaint and get first posi
    setState(() {
      _path = Path();
      _futurePaths = [];
      _paths.add(_path);
      final RenderBox object = context.findRenderObject() as RenderBox;
      final localPosition = object.globalToLocal(details.globalPosition);

      _paths.last.moveTo(localPosition.dx, localPosition.dy);
      print("${localPosition.dx} " "${localPosition.dy}");
      _repaint = true;
    });
  }

  _panUpdate(DragUpdateDetails details) {
    setState(() {
      final RenderBox object = context.findRenderObject() as RenderBox;
      final localPosition = object.globalToLocal(details.globalPosition);
      // // if you choose first update index = end of down to end of update
      // Nối liền các phần tử
      // _paths.first.lineTo(localPosition.dx, localPosition.dy);
      // if you choose last update index = end of down to end of update
      // Tách rời dạng chữ kí
      _paths.last.lineTo(localPosition.dx, localPosition.dy);
    });
  }

  _panEnd(DragEndDetails details) {
    _repaint = false;
  }

  _backClick() {
    if (_paths.isNotEmpty) {
      setState(() {
        _futurePaths.add(_paths.removeLast());
        _repaint = true;
      });
    }
  }

  _forwardClick() {
    if (_futurePaths.isNotEmpty) {
      setState(() {
        final Path path = _futurePaths.removeLast();
        _paths.add(path);
        _repaint = true;
      });
    }
  }

  _clearClick() {
    if (_imgPath!.isNotEmpty) {
      setState(() {
        _imgPath = "";
      });

      if (widget.onTapClearImage != null) {
        widget.onTapClearImage!();
      }

      return;
    }

    setState(() {
      _path = Path();
      _paths = [];
      _repaint = true;
    });
  }
}

class _HandwritingPainter extends CustomPainter {
  List<Path> paths;
  bool repaint;

  _HandwritingPainter({
    required this.paths,
    required this.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.bevel
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (var path in paths) {
      canvas.drawPath(path, paint);
    }

    repaint = false;
  }

  @override
  bool shouldRepaint(_HandwritingPainter oldDelegate) => repaint;
}
