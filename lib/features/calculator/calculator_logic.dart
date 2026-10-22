class CalculatorLogic {
  String _display = '0';
  String _expression = '';
  String _rawInputBuffer = ''; // Used to track secret PIN entered before '='
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  String get display => _display;
  String get expression => _expression;
  String get rawInputBuffer => _rawInputBuffer;

  void appendNumber(String digit) {
    _rawInputBuffer += digit;

    if (_display == '0' || _shouldResetDisplay) {
      _display = digit;
      _shouldResetDisplay = false;
    } else {
      if (_display.length < 12) {
        _display += digit;
      }
    }
  }

  void appendDecimal() {
    if (_shouldResetDisplay) {
      _display = '0.';
      _rawInputBuffer += '0.';
      _shouldResetDisplay = false;
      return;
    }

    if (!_display.contains('.')) {
      _display += '.';
      _rawInputBuffer += '.';
    }
  }

  void setOperator(String op) {
    final currentVal = double.tryParse(_display) ?? 0.0;

    if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
      // Chain calculation: e.g. 5 + 3 + ...
      _calculateResult();
    } else {
      _firstOperand = currentVal;
    }

    _operator = op;
    _expression = '${_formatNumber(_firstOperand!)} $op';
    _shouldResetDisplay = true;
    _rawInputBuffer = ''; // Reset raw buffer when operator is pressed
  }

  void calculate() {
    if (_operator == null || _firstOperand == null) {
      // Just pressing '=' on a number
      return;
    }

    final secondOperand = double.tryParse(_display) ?? 0.0;
    _expression = '${_formatNumber(_firstOperand!)} $_operator ${_formatNumber(secondOperand)} =';

    double result = 0.0;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = 'Error';
          _firstOperand = null;
          _operator = null;
          _shouldResetDisplay = true;
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
    }

    _display = _formatNumber(result);
    _firstOperand = result;
    _operator = null;
    _shouldResetDisplay = true;
  }

  void _calculateResult() {
    if (_operator == null || _firstOperand == null) return;
    final secondOperand = double.tryParse(_display) ?? 0.0;

    double result = 0.0;
    switch (_operator) {
      case '+':
        result = _firstOperand! + secondOperand;
        break;
      case '-':
        result = _firstOperand! - secondOperand;
        break;
      case '×':
        result = _firstOperand! * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _display = 'Error';
          _firstOperand = null;
          _operator = null;
          _shouldResetDisplay = true;
          return;
        }
        result = _firstOperand! / secondOperand;
        break;
    }

    _firstOperand = result;
    _display = _formatNumber(result);
  }

  void toggleSign() {
    if (_display == '0' || _display == 'Error') return;
    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }
  }

  void percentage() {
    final val = double.tryParse(_display);
    if (val != null) {
      final res = val / 100.0;
      _display = _formatNumber(res);
    }
  }

  void clear() {
    _display = '0';
    _expression = '';
    _rawInputBuffer = '';
    _firstOperand = null;
    _operator = null;
    _shouldResetDisplay = false;
  }

  void backspace() {
    if (_display == 'Error' || _display.length <= 1) {
      _display = '0';
    } else {
      _display = _display.substring(0, _display.length - 1);
    }

    if (_rawInputBuffer.isNotEmpty) {
      _rawInputBuffer = _rawInputBuffer.substring(0, _rawInputBuffer.length - 1);
    }
  }

  String _formatNumber(double number) {
    if (number.isNaN || number.isInfinite) return 'Error';
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }
    // Limit decimals to 8 places and strip trailing zeros
    String str = number.toStringAsFixed(8);
    while (str.contains('.') && (str.endsWith('0') || str.endsWith('.'))) {
      str = str.substring(0, str.length - 1);
    }
    return str;
  }
}
