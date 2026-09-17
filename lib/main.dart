import 'package:expressions/expressions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff007aff),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff2f2f7),
        splashFactory: InkSparkle.splashFactory,
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final FocusNode _keyboardFocusNode = FocusNode();
  Color _accentColor = const Color(0xff007aff);
  bool _darkTheme = false;
  double _fontScale = 1;
  bool _filledIcons = false;
  String _expression = '';
  int _cursorPosition = 0;
  String? _result;
  String? _error;
  bool _justEvaluated = false;

  Color get _pageBackground =>
      _darkTheme ? const Color(0xff17181c) : const Color(0xfff2f2f7);

  Color get _surfaceColor =>
      _darkTheme ? const Color(0xff24262d) : const Color(0xeefdfdff);

  Color get _primaryText =>
      _darkTheme ? const Color(0xfff5f5f7) : const Color(0xff1c1c1e);

  Color get _secondaryText =>
      _darkTheme ? const Color(0xffa9abb4) : const Color(0xff8e8e93);

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            void update(VoidCallback change) {
              setState(change);
              sheetSetState(() {});
            }

            return _SettingsSheet(
              accentColor: _accentColor,
              darkTheme: _darkTheme,
              fontScale: _fontScale,
              filledIcons: _filledIcons,
              onAccentChanged: (color) => update(() => _accentColor = color),
              onThemeChanged: (dark) => update(() => _darkTheme = dark),
              onFontScaleChanged: (scale) => update(() => _fontScale = scale),
              onIconStyleChanged: (filled) =>
                  update(() => _filledIcons = filled),
            );
          },
        );
      },
    );
  }

  void _press(String value) {
    setState(() {
      if (_justEvaluated && _isDigitOrDecimal(value)) {
        _expression = '';
        _cursorPosition = 0;
      }
      if (_justEvaluated && _isOperator(value)) {
        _expression = _result ?? '';
        _cursorPosition = _expression.length;
      }
      _justEvaluated = false;
      _error = null;
      _result = null;

      if (_isOperator(value) && _cursorPosition > 0) {
        final last = _expression[_cursorPosition - 1];
        if (_isOperator(last)) {
          _expression =
              _expression.substring(0, _cursorPosition - 1) +
              _expression.substring(_cursorPosition);
          _cursorPosition--;
        }
      }
      _expression =
          _expression.substring(0, _cursorPosition) +
          value +
          _expression.substring(_cursorPosition);
      _cursorPosition += value.length;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _cursorPosition = 0;
      _result = null;
      _error = null;
      _justEvaluated = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_cursorPosition > 0) {
        _expression =
            _expression.substring(0, _cursorPosition - 1) +
            _expression.substring(_cursorPosition);
        _cursorPosition--;
      }
      _result = null;
      _error = null;
      _justEvaluated = false;
    });
  }

  void _delete() {
    setState(() {
      if (_cursorPosition < _expression.length) {
        _expression =
            _expression.substring(0, _cursorPosition) +
            _expression.substring(_cursorPosition + 1);
      }
      _result = null;
      _error = null;
      _justEvaluated = false;
    });
  }

  void _moveCursor(int amount) {
    setState(() {
      _cursorPosition = (_cursorPosition + amount).clamp(0, _expression.length);
      _result = null;
      _error = null;
      _justEvaluated = false;
    });
  }

  void _moveCursorTo(int position) {
    setState(() {
      _cursorPosition = position;
      _result = null;
      _error = null;
      _justEvaluated = false;
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) return;
    try {
      final parsed = Expression.parse(_expression);
      final value = const ExpressionEvaluator().eval(parsed, {});
      if (value is! num || value.isNaN || value.isInfinite) {
        throw const FormatException('The result is not a finite number.');
      }
      setState(() {
        _result = _formatNumber(value);
        _cursorPosition = _expression.length;
        _error = null;
        _justEvaluated = true;
      });
    } catch (_) {
      setState(() {
        _result = null;
        _error = 'Unable to calculate this expression';
        _justEvaluated = false;
      });
    }
  }

  bool _isDigitOrDecimal(String value) => RegExp(r'^[0-9.]$').hasMatch(value);

  bool _isOperator(String value) => RegExp(r'^[+\-*/]$').hasMatch(value);

  // ignore: deprecated_member_use
  void _handleKeyEvent(RawKeyEvent event) {
    // ignore: deprecated_member_use
    if (event is! RawKeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _evaluate();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      _delete();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveCursor(-1);
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveCursor(1);
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _moveCursorTo(0);
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _moveCursorTo(_expression.length);
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _clear();
      return;
    }

    final character = event.character;
    if (character != null &&
        (_isDigitOrDecimal(character) ||
            _isOperator(character) ||
            character == '(' ||
            character == ')')) {
      _press(character);
    }
  }

  String _formatNumber(num value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value
        .toStringAsPrecision(12)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String get _displayExpression =>
      _expression.replaceAll('*', '×').replaceAll('/', '÷');

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    final headerIconSize = isPhone ? 30.0 : 24.0;
    final headerBoxSize = isPhone ? 50.0 : 42.0;
    return Scaffold(
      backgroundColor: _pageBackground,
      // ignore: deprecated_member_use
      body: RawKeyboardListener(
        autofocus: true,
        focusNode: _keyboardFocusNode,
        onKey: _handleKeyEvent,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _darkTheme
                        ? const Color(0xff3a3d46)
                        : const Color(0xffe2e2e8),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 32,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: headerBoxSize,
                          height: headerBoxSize,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.white,
                              _accentColor,
                              _darkTheme ? .28 : .14,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _filledIcons
                                ? Icons.calculate
                                : Icons.calculate_outlined,
                            color: _accentColor,
                            size: headerIconSize,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Calculator App',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openSettings,
                          tooltip: 'Customize appearance',
                          iconSize: isPhone ? 30 : 24,
                          padding: EdgeInsets.all(isPhone ? 9 : 6),
                          constraints: BoxConstraints(
                            minWidth: isPhone ? 52 : 40,
                            minHeight: isPhone ? 52 : 40,
                          ),
                          icon: Icon(Icons.menu_rounded, color: _secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _Display(
                      expression: _displayExpression,
                      cursorPosition: _cursorPosition,
                      result: _result,
                      error: _error,
                      accentColor: _accentColor,
                      darkTheme: _darkTheme,
                      fontScale: _fontScale,
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _buildKeypad()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    final buttons = [
      ('C', _clear, true),
      ('⌫', _backspace, false),
      ('(', () => _press('('), false),
      (')', () => _press(')'), false),
      ('7', () => _press('7'), false),
      ('8', () => _press('8'), false),
      ('9', () => _press('9'), false),
      ('÷', () => _press('/'), false),
      ('4', () => _press('4'), false),
      ('5', () => _press('5'), false),
      ('6', () => _press('6'), false),
      ('×', () => _press('*'), false),
      ('1', () => _press('1'), false),
      ('2', () => _press('2'), false),
      ('3', () => _press('3'), false),
      ('−', () => _press('-'), false),
      ('0', () => _press('0'), false),
      ('.', () => _press('.'), false),
      ('=', _evaluate, false),
      ('+', () => _press('+'), false),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final button = buttons[index];
        final label = button.$1;
        final isClear = button.$3;
        final isEquals = label == '=';
        final isOperator = const {'÷', '×', '−', '+'}.contains(label);
        return FilledButton(
          onPressed: button.$2,
          style: FilledButton.styleFrom(
            backgroundColor: isEquals
                ? _accentColor
                : isClear
                ? const Color(0xffffe6e0)
                : isOperator
                ? Color.lerp(Colors.white, _accentColor, _darkTheme ? .28 : .10)
                : _darkTheme
                ? const Color(0xff30333b)
                : const Color(0xffffffff),
            foregroundColor: isEquals || isClear
                ? isClear
                      ? const Color(0xffc53f2e)
                      : Colors.white
                : _primaryText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
            shadowColor: const Color(0x18000000),
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              fontSize: 22 * _fontScale,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: label == '⌫'
              ? Icon(Icons.backspace_outlined, size: isPhone ? 26 : 20)
              : Text(label),
        );
      },
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.expression,
    required this.cursorPosition,
    required this.accentColor,
    required this.darkTheme,
    required this.fontScale,
    this.result,
    this.error,
  });

  final String expression;
  final int cursorPosition;
  final Color accentColor;
  final bool darkTheme;
  final double fontScale;
  final String? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final display = expression.isEmpty ? '0' : expression;
    final position = cursorPosition.clamp(0, display.length);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        color: darkTheme ? const Color(0xff2d3038) : const Color(0xffffffff),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: darkTheme ? const Color(0xff41444e) : const Color(0xffe3e3e8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: display.substring(0, position)),
                  TextSpan(
                    text: '|',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(text: display.substring(position)),
                  if (result != null) TextSpan(text: ' = $result'),
                ],
                style: TextStyle(
                  color: darkTheme
                      ? const Color(0xfff5f5f7)
                      : const Color(0xff1c1c1e),
                  fontSize: 30 * fontScale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(
                color: darkTheme
                    ? const Color(0xffff9f91)
                    : const Color(0xffc53f2e),
                fontSize: 13 * fontScale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({
    required this.accentColor,
    required this.darkTheme,
    required this.fontScale,
    required this.filledIcons,
    required this.onAccentChanged,
    required this.onThemeChanged,
    required this.onFontScaleChanged,
    required this.onIconStyleChanged,
  });

  final Color accentColor;
  final bool darkTheme;
  final double fontScale;
  final bool filledIcons;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<bool> onIconStyleChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = darkTheme
        ? const Color(0xfff5f5f7)
        : const Color(0xff1c1c1e);
    final secondaryColor = darkTheme
        ? const Color(0xffa9abb4)
        : const Color(0xff8e8e93);
    final sheetColor = darkTheme
        ? const Color(0xff24262d)
        : const Color(0xfffbfbfd);
    final accents = [
      const Color(0xff007aff),
      const Color(0xff34c759),
      const Color(0xffff9500),
      const Color(0xffff2d55),
      const Color(0xff5856d6),
    ];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: darkTheme
                ? const Color(0xff3b3e47)
                : const Color(0xffe3e3e8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: accentColor),
                const SizedBox(width: 10),
                Text(
                  'Customize',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: secondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Theme',
              style: TextStyle(color: secondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Light'),
                  avatar: const Icon(Icons.light_mode_outlined, size: 17),
                  selected: !darkTheme,
                  onSelected: (_) => onThemeChanged(false),
                ),
                ChoiceChip(
                  label: const Text('Dim'),
                  avatar: const Icon(Icons.dark_mode_outlined, size: 17),
                  selected: darkTheme,
                  onSelected: (_) => onThemeChanged(true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Accent color',
              style: TextStyle(color: secondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 9),
            Row(
              children: accents.map((color) {
                final selected = color.toARGB32() == accentColor.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => onAccentChanged(color),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? textColor : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 5),
                        ],
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 17,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Text size',
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${(fontScale * 100).round()}%',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: fontScale,
              min: .85,
              max: 1.2,
              divisions: 7,
              activeColor: accentColor,
              onChanged: onFontScaleChanged,
            ),
            Row(
              children: [
                Text(
                  'Icon style',
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Line')),
                    ButtonSegment(value: true, label: Text('Fill')),
                  ],
                  selected: {filledIcons},
                  onSelectionChanged: (selection) =>
                      onIconStyleChanged(selection.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
