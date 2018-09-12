import 'package:flutter/material.dart';

class Chooser extends StatefulWidget {
  final HeightProvider provideHeight;
  final Widget header;
  final Builder actionsBuilder;
  final List<int> ids;
  final double screenWidth;
  final bool showCollapsed;
  final int initialValue;

  final Sink<ChooserEvent> chooserSink;

  const Chooser(
      {Key key,
      this.header,
      this.actionsBuilder,
      this.ids,
      this.showCollapsed,
      this.initialValue,
      this.provideHeight,
      this.screenWidth,
      this.chooserSink})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ChooserState();
}

typedef ChoiceSelectedListener(int choice);

class _ChooserState extends State<Chooser> with TickerProviderStateMixin {
  ChooserState state;

  AnimationController collapseAnimation;
  AnimationController expandAnimation;

  GlobalKey top = GlobalKey();
  GlobalKey secondary = GlobalKey();
  GlobalKey ternary = GlobalKey();

  // buttons tween
  Tween<Offset> firstOffsetTween;
  Tween<Offset> secondOffsetTween;
  Tween<Offset> thirdOffsetTween;

  // container tween
  Tween<double> cornersTween;
  Tween<double> heightTween;
  ColorTween backgroundTween;

  double targetHeight;
  int selectedId;

  @override
  void initState() {
    expandAnimation =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            _updateStateWithTweens(expandAnimation);
          });

    collapseAnimation =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            _updateStateWithTweens(collapseAnimation);
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.chooserSink.add(ChooserFinished(selectedId));
            }
          });

    state = ChooserState();
    if (widget.showCollapsed) {
      state.height = widget.provideHeight();
      state.corners = 0.0;
      state.background = Colors.transparent;

      state.firstOffset = widget.initialValue == widget.ids[0]
          ? Offset(0.0, 0.0)
          : Offset(-2 * widget.screenWidth, 0.0);
      state.secondOffset = widget.initialValue == widget.ids[1]
          ? Offset(0.0, -(25.0 + 16.0))
          : Offset(-2 * widget.screenWidth, 0.0);
      state.thirdOffset = widget.initialValue == widget.ids[2]
          ? Offset(0.0, -((25.0 + 16.0) * 2))
          : Offset(-2 * widget.screenWidth, 0.0);

      _startExpandAnimation();
    }

    super.initState();
  }

  void _updateStateWithTweens(Animation animation) {
    setState(() {
      state.firstOffset = firstOffsetTween.evaluate(animation);
      state.secondOffset = secondOffsetTween.evaluate(animation);
      state.thirdOffset = thirdOffsetTween.evaluate(animation);

      state.height = heightTween.evaluate(animation);
      state.corners = cornersTween.evaluate(animation);

      state.background = backgroundTween.evaluate(animation);
    });
  }

  @override
  void reassemble() {
    state = ChooserState();
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
            child: Container(color: state.background),
            onTap: () => _startButtonsFadeAnimation(widget.initialValue)),
        SizedBox(
          height: state.height,
          child: Stack(
            children: <Widget>[
              ClipPath(
                clipper: ShapeBorderClipper(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(state.corners),
                            bottomRight: Radius.circular(state.corners)))),
                child: Container(color: Colors.blue),
              ),
              SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    widget.header,
                    SizedBox(height: 16.0),
                    _buildButton(
                        widget.actionsBuilder(context, top, widget.ids[0],
                            () => _startButtonsFadeAnimation(widget.ids[0])),
                        state.firstOffset),
                    SizedBox(height: 16.0),
                    _buildButton(
                        widget.actionsBuilder(context, secondary, widget.ids[1],
                            () => _startButtonsFadeAnimation(widget.ids[1])),
                        state.secondOffset),
                    SizedBox(height: 16.0),
                    _buildButton(
                        widget.actionsBuilder(context, ternary, widget.ids[2],
                            () => _startButtonsFadeAnimation(widget.ids[2])),
                        state.thirdOffset),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _buildButton(Widget child, Offset offset) {
    return Transform(
      child: child,
      transform: Matrix4.translationValues(offset.dx, offset.dy, 0.0),
    );
  }

  _startButtonsFadeAnimation(int selectedId) {
    if (widget.initialValue != selectedId) {
      widget.chooserSink.add(ChooserStarted(selectedId));
    }
    this.selectedId = selectedId;

    firstOffsetTween = selectedId == widget.ids[0]
        ? Tween<Offset>(begin: state.firstOffset, end: state.firstOffset)
        : Tween<Offset>(
            begin: state.firstOffset,
            end: Offset(2 * context.size.width, state.firstOffset.dy));

    secondOffsetTween = selectedId == widget.ids[1]
        ? Tween<Offset>(
            begin: state.secondOffset,
            end: Offset(0.0, -(secondary.currentContext.size.height + 16.0)))
        : Tween<Offset>(
            begin: state.secondOffset,
            end: Offset(2 * context.size.width, state.secondOffset.dy));

    thirdOffsetTween = selectedId == widget.ids[2]
        ? Tween<Offset>(
            begin: state.thirdOffset,
            end:
                Offset(0.0, -((ternary.currentContext.size.height + 16.0) * 2)))
        : Tween<Offset>(
            begin: state.thirdOffset,
            end: Offset(2 * context.size.width, state.thirdOffset.dy));

    heightTween =
        Tween<double>(begin: state.height, end: widget.provideHeight());
    cornersTween = Tween<double>(begin: state.corners, end: 0.0);
    backgroundTween =
        ColorTween(begin: state.background, end: Colors.transparent);

    collapseAnimation.forward();
  }

  _startExpandAnimation() {
    firstOffsetTween =
        Tween<Offset>(begin: state.firstOffset, end: Offset(0.0, 0.0));
    secondOffsetTween =
        Tween<Offset>(begin: state.secondOffset, end: Offset(0.0, 0.0));
    thirdOffsetTween =
        Tween<Offset>(begin: state.thirdOffset, end: Offset(0.0, 0.0));

    heightTween = Tween<double>(begin: state.height, end: 400.0);
    cornersTween = Tween<double>(begin: state.corners, end: 50.0);
    backgroundTween = ColorTween(begin: state.background, end: Colors.black26);

    expandAnimation.forward();
  }

  @override
  void dispose() {
    collapseAnimation.dispose();
    expandAnimation.dispose();
    super.dispose();
  }
}

class ChooserClipper extends ShapeBorderClipper {}

class ChooserState {
  Color background = Colors.black26;

  Offset firstOffset = Offset(0.0, 0.0);
  Offset secondOffset = Offset(0.0, 0.0);
  Offset thirdOffset = Offset(0.0, 0.0);

  double corners = 50.0;
  double height = 400.0;
}

typedef double HeightProvider();

typedef Widget Builder(
    BuildContext context, Key key, int id, VoidCallback pressed);

abstract class ChooserEvent {
  final int id;

  const ChooserEvent(this.id);
}

class ChooserStarted extends ChooserEvent {
  const ChooserStarted(int id) : super(id);
}

class ChooserFinished extends ChooserEvent {
  const ChooserFinished(int id) : super(id);
}
