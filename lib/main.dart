import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Sliders',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(title: 'Custom Sliders'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _value = 0.0;
  bool _enabled = true;
  bool _slow = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Defines the theme of all sliders below the SliderTheme widget.
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(
      activeTrackColor: Colors.deepPurple,
      inactiveTrackColor: Colors.black26,
      activeTickMarkColor: Colors.white70,
      inactiveTickMarkColor: Colors.black,
      overlayColor: Colors.black12,
      thumbColor: Colors.deepPurple,
      valueIndicatorColor: Colors.deepPurpleAccent,
      thumbShape: CustomSliderThumbShape(),
      valueIndicatorShape: CustomSliderValueIndicatorShape(),
      valueIndicatorTextStyle:
          theme.accentTextTheme.body2.copyWith(color: Colors.white),
    );

    return SliderTheme(
      data: sliderTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                      value: _enabled,
                      onChanged: (bool value) {
                        setState(() {
                          _enabled = value;
                        });
                      }),
                  Text('Enabled'),
                  Checkbox(
                      value: _slow,
                      onChanged: (bool value) {
                        setState(() {
                          timeDilation = value ? 10.0 : 1.0;
                          _slow = value;
                        });
                      }),
                  Text('Slow'),
                ],
              ),
              Slider(
                value: _value,
                label: _value.toStringAsFixed(0),
                divisions: 10,
                min: 0.0,
                max: 100.0,
                onChanged: _enabled
                    ? (double value) {
                        setState(() {
                          _value = value;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The number of sides of the thumb and value indicator.
const int _sides = 8;
// The angle that will rotate the shape so that there is one flat side down.
const double _startAngle = math.pi / (1.0 * _sides) + math.pi / 2.0;

// Generates a path for a polygon of a particular radius, with a specific number
// of sides, rotated by an initial angle, centered on a particular center point.
Path polygon(double size, Offset center) {
  final Path thumbPath = Path();
  final double delta = math.pi * 2.0 / _sides.toDouble();
  final double startX = center.dx + size * math.cos(_startAngle);
  final double startY = center.dy + size * math.sin(_startAngle);
  thumbPath.moveTo(startX, startY);
  for (double theta = 0.0; theta < math.pi * 2.0; theta += delta) {
    final double x = center.dx + size * math.cos(theta + _startAngle);
    final double y = center.dy + size * math.sin(theta + _startAngle);
    thumbPath.lineTo(x, y);
  }
  thumbPath.close();
  return thumbPath;
}

/// The class defining the custom thumb shape.
class CustomSliderThumbShape extends SliderComponentShape {
  // The radius of the thumb.
  static const double _thumbSize = 3.0;
  // The radius of the thumb for a disabled slider.
  static const double _disabledThumbSize = 2.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return isEnabled
        ? const Size.fromRadius(_thumbSize)
        : const Size.fromRadius(_disabledThumbSize);
  }

  /// Describes the linear interpolation between the disabled thumb size, and
  /// the non-disabled thumb size, so that it can animate when the thumb is
  /// enabled/disabled.
  static final Tween<double> sizeTween = Tween<double>(
    begin: _disabledThumbSize,
    end: _thumbSize,
  );

  /// This is where the magic happens.
  /// This draws a simple polygon for the thumb.
  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    // The Tween that interpolates between the disabled and enabled thumb colors.
    final Paint paintColor = Paint()..color = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    ).evaluate(enableAnimation);
    // Draw the polygon used for the thumb of the appropriate size.
    context.canvas.drawPath(
      polygon(_thumbSize * sizeTween.evaluate(enableAnimation), thumbCenter),
      paintColor,
    );
  }
}

/// The Shape class that defines the value indicator.
class CustomSliderValueIndicatorShape extends SliderComponentShape {
  // Radius of the fully-activated value indicator
  static const double _indicatorSize = 18.0;
  static const double _activationHeight = 60.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(_indicatorSize);
  }

  /// The Tween used to grow the indicator out from the thumb.
  static final Tween<double> sizeTween = Tween<double>(
    begin: 0.0,
    end: _indicatorSize,
  );

  /// The Tween used to slide the indicator up from the thumb.
  static final Tween<double> activationTween = Tween<double>(
    begin: 0.0,
    end: _activationHeight,
  );

  /// Draws the connecting triangle between the bottom of the polygon and the
  /// center of the thumb.
  Path connector(Offset thumbCenter, Offset indicatorCenter, double size) {
    final double halfChordLength = size * math.sin(math.pi / _sides);
    final double shapeBottom =
        thumbCenter.dy + indicatorCenter.dy + size * math.sin(_startAngle);
    final Path connectorPath = Path();
    connectorPath.moveTo(thumbCenter.dx, thumbCenter.dy);
    connectorPath.lineTo(thumbCenter.dx + halfChordLength, shapeBottom);
    connectorPath.lineTo(thumbCenter.dx - halfChordLength, shapeBottom);
    connectorPath.close();
    return connectorPath;
  }

  /// This draws a regular polygon for the value indicator, and a "neck" that
  /// consists of a triangle drawn from the flat bottom of the polygon to the
  /// center of the thumb.
  @override
  void paint(
    PaintingContext context,
    Offset thumbCenter, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    // The color to paint the value indicator polygon.
    final Paint paintColor = Paint()
      ..color = sliderTheme.valueIndicatorColor
          .withAlpha((255.0 * activationAnimation.value).round());
    // The radius of the value indicator polygon, which grows as it is activated.
    final double radius = sizeTween.evaluate(activationAnimation);
    // The offset of the value indicator's position as it is activated.
    final Offset indicatorCenter =
        Offset(0.0, -activationTween.evaluate(activationAnimation));
    // The path used to draw the value indicator polygon.
    context.canvas
        .drawPath(polygon(radius, thumbCenter + indicatorCenter), paintColor);
    // The path used to draw the neck between the thumb and the value indicator polygon.
    context.canvas
        .drawPath(connector(thumbCenter, indicatorCenter, radius), paintColor);
    // An offset that will center the label on 0,0.
    final Offset labelCenter =
        Offset(-labelPainter.width / 2.0, -labelPainter.height / 2.0);
    // Paints the label at the center of the value indicator.
    labelPainter.paint(
        context.canvas, thumbCenter + indicatorCenter + labelCenter);
  }
}
