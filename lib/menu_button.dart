library menu_button;

import 'package:flutter/material.dart';

class MenuButton<T> extends StatefulWidget {
  const MenuButton({
    @required final this.child,
    @required final this.items,
    @required final this.itemBuilder,
    final this.toggledChild,
    final this.divider,
    final this.topDivider = true,
    final this.onItemSelected,
    final this.decoration,
    final this.onMenuButtonToggle,
    final this.scrollPhysics,
    final this.popupHeight,
    final this.crossTheEdge = false,
    final this.edgeMargin = 0.0,
    final this.dontShowTheSameItemSelected = false,
    final this.selectedItem,
    final this.label,
    final this.showBoxShadow = true,
    final this.labelDecoration,
  })  : assert(child != null),
        assert(items != null),
        assert(itemBuilder != null),
        assert(!dontShowTheSameItemSelected || selectedItem != null);

  final Widget child;
  final Widget toggledChild;
  final MenuItemBuilder<T> itemBuilder;
  final Widget divider;
  final bool topDivider;
  final List<T> items;
  final MenuItemSelected<T> onItemSelected;
  final BoxDecoration decoration;
  final MenuButtonToggleCallback onMenuButtonToggle;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;
  final bool crossTheEdge;
  final double edgeMargin;
  final bool dontShowTheSameItemSelected;
  final T selectedItem;
  final Text label;
  final LabelDecoration labelDecoration;
  final bool showBoxShadow;

  @override
  State<StatefulWidget> createState() => _MenuButtonState<T>();
}

class _MenuButtonState<T> extends State<MenuButton<T>> {
  T oldItem;
  T selectedItem;

  LabelDecoration labelDecoration;
  Size labelTextSize;
  bool toggledMenu = false;
  Widget button;
  double buttonWidth;

  void _updateLabelTextSize() {
    if (widget.label != null) {
      setState(
        () => labelTextSize = MenuButtonUtils.getTextSize(
          widget.label.data,
          widget.label.style,
        ),
      );
    }
  }

  void _updateButton() {
    setState(
      () => button = InkWell(
        child: Container(
          decoration: widget.decoration,
          child: widget.child,
        ),
        onTap: togglePopup,
      ),
    );
  }

  void _updateLabelDecoration() {
    setState(
      () {
        if (widget.labelDecoration == null) {
          labelDecoration = LabelDecoration(
            verticalMenuPadding: 12,
          );
        } else {
          labelDecoration = widget.labelDecoration;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(
      () => button = InkWell(
        child: Container(
          decoration: widget.decoration,
          child: widget.child,
        ),
        onTap: togglePopup,
      ),
    );
    _updateLabelDecoration();
    _updateLabelTextSize();
  }

  @override
  void didUpdateWidget(MenuButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateLabelTextSize();
    _updateLabelDecoration();
    _updateButton();
  }

  @override
  Widget build(BuildContext context) {
    return widget.label == null
        ? button
        : Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: labelDecoration.verticalMenuPadding,
                ),
                child: button,
              ),
              Positioned(
                top: labelDecoration.verticalMenuPadding,
                left: labelDecoration.leftPosition,
                child: Container(
                  width: labelTextSize.width + labelDecoration.leftPosition,
                  height: widget.decoration.border.top.width,
                  color: Theme.of(context).backgroundColor,
                ),
              ),
              Positioned(
                top: labelDecoration.verticalMenuPadding / 2,
                left: labelDecoration.leftPosition,
                child: Container(
                  // color: widget.decoration.color,
                  color: labelDecoration.background ??
                      Theme.of(context).backgroundColor,
                  width: labelTextSize.width + labelDecoration.leftPosition,
                  height: labelTextSize.height / 2,
                ),
              ),
              Positioned(
                top: labelDecoration.verticalMenuPadding,
                left: labelDecoration.leftPosition,
                child: Container(
                  color: labelDecoration.background ?? widget.decoration.color,
                  width: labelTextSize.width + labelDecoration.leftPosition,
                  height: labelTextSize.height / 2,
                ),
              ),
              Positioned(
                top: (0 - labelTextSize.height / 2) +
                    labelDecoration.verticalMenuPadding,
                left: labelDecoration.leftPosition +
                    labelDecoration.leftPosition / 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  opacity: toggledMenu ? 0 : 1,
                  child: widget.label,
                ),
              ),
            ],
          );
  }

  void togglePopup() {
    setState(() => toggledMenu = !toggledMenu);
    widget.onMenuButtonToggle(toggledMenu);
    if (widget.dontShowTheSameItemSelected) {
      setState(() => selectedItem = widget.selectedItem);
      MenuButtonUtils.dontShowTheSameItemSelected(
          oldItem, selectedItem, widget.items);
    }

    final List<Widget> items = widget.items
        .map((T value) => _MenuItem<T>(
              value: value,
              child: widget.itemBuilder(value),
            ))
        .toList();
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    buttonWidth = button.size.width;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
            Offset(
                0,
                widget.labelDecoration != null
                    ? widget.labelDecoration.verticalMenuPadding
                    : 0),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (items.isNotEmpty) {
      _togglePopup(
        context: context,
        position: position,
        items: items,
        toggledChild: widget.toggledChild,
        divider: widget.divider,
        topDivider: widget.topDivider,
        decoration: widget.decoration,
        scrollPhysics: widget.scrollPhysics,
        popupHeight: widget.popupHeight,
        edgeMargin: widget.edgeMargin,
        crossTheEdge: widget.crossTheEdge,
        showBoxShadow: widget.showBoxShadow,
      ).then<void>((T newValue) {
        setState(() => toggledMenu = !toggledMenu);
        widget.onMenuButtonToggle(toggledMenu);

        if (widget.dontShowTheSameItemSelected) {
          setState(() => oldItem = selectedItem);
          setState(() => selectedItem = newValue);
        }
        if (mounted && newValue != null && widget.onItemSelected != null) {
          widget.onItemSelected(newValue);
        }
      });
    }
  }

  Future<T> _togglePopup({
    @required BuildContext context,
    @required RelativeRect position,
    @required List<Widget> items,
    Widget toggledChild,
    Widget divider,
    bool topDivider,
    BoxDecoration decoration,
    ScrollPhysics scrollPhysics,
    double popupHeight,
    bool crossTheEdge,
    double edgeMargin,
    bool showBoxShadow,
  }) =>
      Navigator.push(
        context,
        _MenuRoute<T>(
          position: position,
          items: items,
          toggledChild: toggledChild,
          divider: divider,
          topDivider: topDivider,
          decoration: decoration,
          scrollPhysics: scrollPhysics,
          popupHeight: popupHeight,
          crossTheEdge: crossTheEdge,
          edgeMargin: edgeMargin,
          buttonWidth: buttonWidth,
          showBoxShadow: showBoxShadow,
        ),
      );
}

class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({
    final this.position,
    final this.items,
    final this.toggledChild,
    final this.divider,
    final this.topDivider,
    final this.decoration,
    final this.scrollPhysics,
    final this.popupHeight,
    final this.crossTheEdge,
    final this.edgeMargin,
    final this.buttonWidth,
    final this.showBoxShadow,
  });

  final RelativeRect position;
  final List<Widget> items;
  final Widget toggledChild;
  final Widget divider;
  final bool topDivider;
  final BoxDecoration decoration;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;
  final bool crossTheEdge;
  final double edgeMargin;
  final double buttonWidth;
  final bool showBoxShadow;

  @override
  Color get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Animation<double> createAnimation() => CurvedAnimation(
        parent: super.createAnimation(),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Builder(
          builder: (BuildContext context) {
            return CustomSingleChildLayout(
              delegate: _MenuRouteLayout(
                position,
              ),
              child: _Menu<T>(
                route: this,
                scrollPhysics: scrollPhysics,
                popupHeight: popupHeight,
                crossTheEdge: crossTheEdge,
                edgeMargin: edgeMargin,
                buttonWidth: buttonWidth,
                showBoxShadow: showBoxShadow,
              ),
            );
          },
        ),
      );
}

// Positioning of the menu on the screen.
class _MenuRouteLayout extends SingleChildLayoutDelegate {
  _MenuRouteLayout(this.position);

  // Rectangle of underlying button, relative to the overlay's dimensions.
  final RelativeRect position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // The menu can be at most the size of the overlay minus 8.0 pixels in each
    // direction.
    return BoxConstraints.loose(constraints.biggest);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      Offset(position.left, position.top);

  @override
  bool shouldRelayout(_MenuRouteLayout oldDelegate) =>
      position != oldDelegate.position;
}

class _Menu<T> extends StatefulWidget {
  const _Menu({
    Key key,
    this.route,
    this.scrollPhysics,
    this.popupHeight,
    this.edgeMargin,
    this.crossTheEdge,
    this.showBoxShadow,
    @required this.buttonWidth,
  }) : super(key: key);

  final _MenuRoute<T> route;
  final ScrollPhysics scrollPhysics;
  final double popupHeight;
  final bool crossTheEdge;
  final double edgeMargin;
  final double buttonWidth;
  final bool showBoxShadow;

  @override
  __MenuState<T> createState() => __MenuState<T>();
}

class __MenuState<T> extends State<_Menu<T>> {
  final GlobalKey key = GlobalKey();
  double width;

  @override
  void initState() {
    super.initState();
    if (widget.crossTheEdge == true) {
      WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
        final RenderBox renderBox =
            key.currentContext.findRenderObject() as RenderBox;
        final Offset offset = renderBox.globalToLocal(Offset.zero);
        final double x = offset.dx.abs();
        final double screenWidth = MediaQuery.of(context).size.width;

        setState(() => width = screenWidth - x - widget.edgeMargin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (widget.route.topDivider) {
      children.add(widget.route.divider);
    }

    for (int i = 0; i < widget.route.items.length; i += 1) {
      children.add(widget.route.items[i]);

      if (i < widget.route.items.length - 1) {
        children.add(widget.route.divider);
      }
    }

    final CurveTween opacity =
        CurveTween(curve: const Interval(0.0, 1.0 / 8.0));
    final CurveTween height = CurveTween(curve: const Interval(0.0, .9));
    final CurveTween shadow = CurveTween(curve: const Interval(0.0, 1.0 / 4.0));

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: widget.route.animation,
        builder: (BuildContext context, Widget child) => Opacity(
          opacity: opacity.evaluate(widget.route.animation),
          child: Container(
            key: key,
            width: width ?? widget.buttonWidth,
            height: widget.popupHeight,
            decoration: BoxDecoration(
              color: widget.route.decoration.color,
              border: widget.route.decoration.border,
              borderRadius: widget.route.decoration.borderRadius,
              boxShadow: widget.route.showBoxShadow
                  ? <BoxShadow>[
                      BoxShadow(
                          color: Color.fromARGB(
                              (20 * shadow.evaluate(widget.route.animation))
                                  .toInt(),
                              0,
                              0,
                              0),
                          offset: Offset(0.0,
                              3.0 * shadow.evaluate(widget.route.animation)),
                          blurRadius:
                              5.0 * shadow.evaluate(widget.route.animation))
                    ]
                  : <BoxShadow>[],
            ),
            child: ClipRRect(
              borderRadius:
                  widget.route.decoration.borderRadius as BorderRadius,
              child: IntrinsicWidth(
                child: SingleChildScrollView(
                  physics: widget.scrollPhysics ??
                      const NeverScrollableScrollPhysics(),
                  child: ListBody(children: <Widget>[
                    _MenuButtonToggledChild(child: widget.route.toggledChild),
                    Align(
                      alignment: AlignmentDirectional.topStart,
                      widthFactor: 1.0,
                      heightFactor: height.evaluate(widget.route.animation),
                      child: SingleChildScrollView(
                        child: ListBody(
                          children: children,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButtonToggledChild extends StatelessWidget {
  const _MenuButtonToggledChild({@required final this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: child,
    );
  }
}

class _MenuItem<T> extends StatelessWidget {
  const _MenuItem({this.value, @required final this.child});

  final T value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: .0,
      color: Colors.transparent,
      child: InkWell(
          onTap: () => Navigator.of(context).pop<T>(value), child: child),
    );
  }
}

class LabelDecoration {
  LabelDecoration({
    @required this.verticalMenuPadding,
    this.leftPosition = 6,
    this.background = Colors.white,
  });

  double verticalMenuPadding;
  double leftPosition;
  Color background;
}

class MenuButtonUtils {
  static Size getTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  static Map<String, dynamic> dontShowTheSameItemSelected(
      dynamic oldSelected, dynamic selectedItem, List<Object> items) {
    if (oldSelected != selectedItem) {
      final Map<String, Object> res = <String, Object>{
        'oldSelected': oldSelected,
        'selectedItem': selectedItem,
        'items': items,
      };

      if (oldSelected == null) {
        items.removeWhere((dynamic element) => element == selectedItem);
        return res;
      }

      bool isOldSelectedAlready = false;
      items.forEach((dynamic element) {
        if (element == oldSelected) {
          isOldSelectedAlready = true;
        }
      });

      items.removeWhere((Object element) => element == selectedItem);
      if (!isOldSelectedAlready) {
        items.add(oldSelected);
      }

      return res;
    }

    return <String, Object>{};
  }
}

typedef MenuButtonToggleCallback = void Function(bool isToggle);

typedef MenuItemBuilder<T> = Widget Function(T value);

typedef MenuItemSelected<T> = void Function(T value);
