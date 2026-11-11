import 'package:flutter/material.dart';

/// White form dropdown whose menu always opens below the field (flipping up
/// only when there is no room), matches the field's width, and animates open
/// and closed with a fade + grow.
class AppDropdownField<T> extends FormField<T> {
  AppDropdownField({
    super.key,
    required List<T> values,
    required String Function(T) labelOf,
    super.initialValue,
    ValueChanged<T?>? onChanged,
    super.validator,
    String? hintText,
  }) : super(
         builder: (field) => _DropdownBody<T>(
           field: field,
           values: values,
           labelOf: labelOf,
           hintText: hintText,
           onChanged: onChanged,
         ),
       );
}

class _DropdownBody<T> extends StatefulWidget {
  const _DropdownBody({
    required this.field,
    required this.values,
    required this.labelOf,
    required this.onChanged,
    this.hintText,
  });

  final FormFieldState<T> field;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T?>? onChanged;
  final String? hintText;

  @override
  State<_DropdownBody<T>> createState() => _DropdownBodyState<T>();
}

class _DropdownBodyState<T> extends State<_DropdownBody<T>>
    with SingleTickerProviderStateMixin {
  static const _itemHeight = 48.0;
  static const _gap = 4.0;

  final _link = LayerLink();
  final _portal = OverlayPortalController();
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    reverseDuration: const Duration(milliseconds: 150),
  );
  bool _openUp = false;
  Size _fieldSize = Size.zero;

  bool get _isOpen =>
      _portal.isShowing && _anim.status != AnimationStatus.reverse;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    _fieldSize = box.size;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.of(context);
    final menuH = _itemHeight * widget.values.length + 16;
    final below =
        screen.size.height -
        screen.viewInsets.bottom -
        screen.padding.bottom -
        (top + _fieldSize.height);
    _openUp = below < menuH + _gap && top > below;
    FocusScope.of(context).unfocus();
    setState(_portal.show);
    _anim.forward(from: 0);
  }

  Future<void> _close() async {
    await _anim.reverse();
    if (mounted) setState(_portal.hide);
  }

  void _select(T v) {
    widget.field.didChange(v);
    widget.onChanged?.call(v);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.field.value;
    final theme = Theme.of(context);
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (_) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: _openUp ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor: _openUp
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: Offset(0, _openUp ? -_gap : _gap),
              child: SizedBox(
                width: _fieldSize.width,
                child: _menu(theme, value),
              ),
            ),
          ],
        ),
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            isFocused: _isOpen,
            isEmpty: value == null,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: widget.field.errorText,
              suffixIcon: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(parent: _anim, curve: Curves.easeOut),
                ),
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            child: Text(
              value == null ? '' : widget.labelOf(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(ThemeData theme, T? selected) {
    final curve = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: curve,
      child: SizeTransition(
        sizeFactor: curve,
        alignment: _openUp ? Alignment.bottomCenter : Alignment.topCenter,
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final v in widget.values)
                  InkWell(
                    onTap: () => _select(v),
                    child: Container(
                      height: _itemHeight,
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: v == selected ? const Color(0xFFF2F2F2) : null,
                      child: Text(
                        widget.labelOf(v),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
