import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/services/secure_storage_service.dart';
import '../auth/biometric_service.dart';
import '../auth/pin_service.dart';
import '../auth/secret_code_detector.dart';
import 'calculator_logic.dart';
import 'widgets/calc_button.dart';
import 'widgets/calc_display.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorLogic _calculator = CalculatorLogic();
  late final PinService _pinService;
  late final SecretCodeDetector _secretDetector;
  late final BiometricService _biometricService;
  bool _isVaultConfigured = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    final storage = SecureStorageService();
    _pinService = PinService(storageService: storage);
    _secretDetector = SecretCodeDetector(pinService: _pinService);
    _biometricService = BiometricService(storageService: storage);
    _checkInitStatus();
  }

  Future<void> _checkInitStatus() async {
    final isSet = await _pinService.isPinSet();
    final hasBiometric = await _biometricService.isBiometricEnabledByUser();
    if (mounted) {
      setState(() {
        _isVaultConfigured = isSet;
        _biometricAvailable = hasBiometric;
      });
    }
  }

  Future<void> _onEqualsPressed() async {
    // 1. If vault PIN is not set yet, check if user pressed '=' after typing numbers to guide them
    if (!_isVaultConfigured) {
      final input = _calculator.rawInputBuffer.isNotEmpty
          ? _calculator.rawInputBuffer
          : _calculator.display;
      if (input.length >= 4 && double.tryParse(input) != null) {
        _promptFirstTimeSetup(input);
        return;
      }
      setState(() {
        _calculator.calculate();
      });
      return;
    }

    // 2. Secret check: candidate from raw input buffer or current display
    final candidate = _calculator.rawInputBuffer.isNotEmpty
        ? _calculator.rawInputBuffer
        : _calculator.display;

    final isSecretMatched = await _secretDetector.checkCandidate(candidate);

    if (isSecretMatched && mounted) {
      _calculator.clear();
      setState(() {});
      _navigateToVault();
      return;
    }

    // 3. Not secret: act as normal calculator!
    setState(() {
      _calculator.calculate();
    });
  }

  void _promptFirstTimeSetup(String suggestedPin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.vaultSurface,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.vaultAccent),
            SizedBox(width: 8),
            Text('Secret Vault Setup'),
          ],
        ),
        content: Text(
          'Would you like to set "$suggestedPin" as your Secret Vault PIN?\n\n'
          'Whenever you type your PIN and press "=", the secret photo vault will open.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _calculator.calculate();
              });
            },
            child: const Text('Just Calculate', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.setupPin);
            },
            child: const Text('Setup Vault'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryBiometricUnlock() async {
    final success = await _biometricService.authenticate();
    if (success && mounted) {
      _navigateToVault();
    }
  }

  void _navigateToVault() {
    Navigator.of(context).pushNamed(AppRoutes.vaultHome).then((_) {
      _checkInitStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.calcBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.calcBackground,
        elevation: 0,
        title: const Text(
          'Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          if (_biometricAvailable)
            IconButton(
              icon: const Icon(Icons.fingerprint, color: AppTheme.vaultAccent, size: 26),
              tooltip: 'Biometric Unlock',
              onPressed: _tryBiometricUnlock,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {
              if (!_isVaultConfigured) {
                Navigator.pushNamed(context, AppRoutes.setupPin);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Expanded(
              child: CalcDisplay(
                display: _calculator.display,
                expression: _calculator.expression,
                onSecretTap: () {
                  if (_biometricAvailable) {
                    _tryBiometricUnlock();
                  } else if (!_isVaultConfigured) {
                    Navigator.pushNamed(context, AppRoutes.setupPin);
                  }
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Calculator Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      CalcButton(
                        text: _calculator.display == '0' ? 'AC' : 'C',
                        backgroundColor: AppTheme.calcBtnAction,
                        textColor: AppTheme.calcBtnActionText,
                        onTap: () => setState(() => _calculator.clear()),
                      ),
                      CalcButton(
                        text: '+/-',
                        backgroundColor: AppTheme.calcBtnAction,
                        textColor: AppTheme.calcBtnActionText,
                        onTap: () => setState(() => _calculator.toggleSign()),
                      ),
                      CalcButton(
                        text: '%',
                        backgroundColor: AppTheme.calcBtnAction,
                        textColor: AppTheme.calcBtnActionText,
                        onTap: () => setState(() => _calculator.percentage()),
                      ),
                      CalcButton(
                        text: '÷',
                        backgroundColor: AppTheme.calcBtnOperator,
                        textColor: AppTheme.calcBtnOperatorText,
                        onTap: () => setState(() => _calculator.setOperator('÷')),
                      ),
                    ],
                  ),
                  // Row 2
                  Row(
                    children: [
                      CalcButton(
                        text: '7',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('7')),
                      ),
                      CalcButton(
                        text: '8',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('8')),
                      ),
                      CalcButton(
                        text: '9',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('9')),
                      ),
                      CalcButton(
                        text: '×',
                        backgroundColor: AppTheme.calcBtnOperator,
                        textColor: AppTheme.calcBtnOperatorText,
                        onTap: () => setState(() => _calculator.setOperator('×')),
                      ),
                    ],
                  ),
                  // Row 3
                  Row(
                    children: [
                      CalcButton(
                        text: '4',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('4')),
                      ),
                      CalcButton(
                        text: '5',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('5')),
                      ),
                      CalcButton(
                        text: '6',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('6')),
                      ),
                      CalcButton(
                        text: '-',
                        backgroundColor: AppTheme.calcBtnOperator,
                        textColor: AppTheme.calcBtnOperatorText,
                        onTap: () => setState(() => _calculator.setOperator('-')),
                      ),
                    ],
                  ),
                  // Row 4
                  Row(
                    children: [
                      CalcButton(
                        text: '1',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('1')),
                      ),
                      CalcButton(
                        text: '2',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('2')),
                      ),
                      CalcButton(
                        text: '3',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('3')),
                      ),
                      CalcButton(
                        text: '+',
                        backgroundColor: AppTheme.calcBtnOperator,
                        textColor: AppTheme.calcBtnOperatorText,
                        onTap: () => setState(() => _calculator.setOperator('+')),
                      ),
                    ],
                  ),
                  // Row 5
                  Row(
                    children: [
                      CalcButton(
                        text: '0',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendNumber('0')),
                      ),
                      CalcButton(
                        text: '.',
                        backgroundColor: AppTheme.calcBtnNum,
                        textColor: AppTheme.calcBtnNumText,
                        onTap: () => setState(() => _calculator.appendDecimal()),
                      ),
                      CalcButton(
                        icon: const Icon(Icons.backspace_outlined, color: AppTheme.calcBtnActionText, size: 24),
                        backgroundColor: AppTheme.calcBtnAction,
                        textColor: AppTheme.calcBtnActionText,
                        onTap: () => setState(() => _calculator.backspace()),
                      ),
                      CalcButton(
                        text: '=',
                        backgroundColor: AppTheme.calcEquals,
                        textColor: Colors.white,
                        onTap: _onEqualsPressed,
                        onLongPress: () {
                          if (_biometricAvailable) {
                            _tryBiometricUnlock();
                          } else if (!_isVaultConfigured) {
                            Navigator.pushNamed(context, AppRoutes.setupPin);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
