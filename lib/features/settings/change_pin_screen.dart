import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/services/secure_storage_service.dart';
import '../auth/pin_service.dart';

enum ChangePinStep { verifyOld, enterNew, confirmNew }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final PinService _pinService = PinService(storageService: SecureStorageService());

  ChangePinStep _step = ChangePinStep.verifyOld;
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  void _onDigitTap(String digit) {
    setState(() {
      _errorMessage = null;
      switch (_step) {
        case ChangePinStep.verifyOld:
          if (_oldPin.length < 8) _oldPin += digit;
          break;
        case ChangePinStep.enterNew:
          if (_newPin.length < 8) _newPin += digit;
          break;
        case ChangePinStep.confirmNew:
          if (_confirmPin.length < 8) _confirmPin += digit;
          break;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      switch (_step) {
        case ChangePinStep.verifyOld:
          if (_oldPin.isNotEmpty) _oldPin = _oldPin.substring(0, _oldPin.length - 1);
          break;
        case ChangePinStep.enterNew:
          if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
          break;
        case ChangePinStep.confirmNew:
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
          break;
      }
    });
  }

  Future<void> _onNext() async {
    switch (_step) {
      case ChangePinStep.verifyOld:
        final isValid = await _pinService.verifyPin(_oldPin);
        if (!isValid) {
          setState(() {
            _errorMessage = 'Incorrect current PIN. Try again.';
            _oldPin = '';
          });
          return;
        }
        setState(() {
          _step = ChangePinStep.enterNew;
          _errorMessage = null;
        });
        break;

      case ChangePinStep.enterNew:
        if (_newPin.length < 4) {
          setState(() {
            _errorMessage = 'New PIN must be at least 4 digits.';
          });
          return;
        }
        setState(() {
          _step = ChangePinStep.confirmNew;
          _errorMessage = null;
        });
        break;

      case ChangePinStep.confirmNew:
        if (_confirmPin != _newPin) {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _confirmPin = '';
          });
          return;
        }
        final success = await _pinService.changePin(_oldPin, _newPin);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN updated successfully!'),
              backgroundColor: AppTheme.vaultAccentGreen,
            ),
          );
          Navigator.of(context).pop();
        }
        break;
    }
  }

  String get _currentInput {
    switch (_step) {
      case ChangePinStep.verifyOld:
        return _oldPin;
      case ChangePinStep.enterNew:
        return _newPin;
      case ChangePinStep.confirmNew:
        return _confirmPin;
    }
  }

  String get _title {
    switch (_step) {
      case ChangePinStep.verifyOld:
        return 'Enter Current PIN';
      case ChangePinStep.enterNew:
        return 'Enter New Secret PIN';
      case ChangePinStep.confirmNew:
        return 'Confirm New PIN';
    }
  }

  String get _subtitle {
    switch (_step) {
      case ChangePinStep.verifyOld:
        return 'Verify your existing PIN to continue';
      case ChangePinStep.enterNew:
        return 'Choose 4 to 8 digits for your new PIN';
      case ChangePinStep.confirmNew:
        return 'Re-enter your new PIN to confirm';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vaultBg,
      appBar: AppBar(
        title: const Text('Change PIN'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              _title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _currentInput.length.clamp(4, 8),
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: index < _currentInput.length
                        ? AppTheme.vaultAccent
                        : AppTheme.vaultBorder,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.vaultDanger, fontSize: 13),
              ),
            ],
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _currentInput.length >= 4 ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vaultAccent,
                    disabledBackgroundColor: AppTheme.vaultBorder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _step == ChangePinStep.confirmNew ? 'Save New PIN' : 'Next',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        _buildKeypadRow(['4', '5', '6']),
        _buildKeypadRow(['7', '8', '9']),
        _buildKeypadRow(['', '0', 'backspace']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: values.map((val) {
          if (val.isEmpty) {
            return const SizedBox(width: 72, height: 60);
          }
          if (val == 'backspace') {
            return InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 72,
                height: 60,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.backspace_outlined,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
              ),
            );
          }
          return InkWell(
            onTap: () => _onDigitTap(val),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 72,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.vaultSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.vaultBorder.withValues(alpha: 0.5)),
              ),
              child: Text(
                val,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
