import 'package:flutter/material.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/services/secure_storage_service.dart';
import 'pin_service.dart';

class SetupPinScreen extends StatefulWidget {
  final bool isFirstTime;

  const SetupPinScreen({super.key, this.isFirstTime = true});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final PinService _pinService = PinService(storageService: SecureStorageService());
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onNumberTap(String number) {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.length < 8) {
          _firstPin += number;
        }
      } else {
        if (_confirmPin.length < 8) {
          _confirmPin += number;
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _onNextOrConfirm() async {
    if (!_isConfirming) {
      if (_firstPin.length < 4) {
        setState(() {
          _errorMessage = 'PIN must be at least 4 digits';
        });
        return;
      }
      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });
    } else {
      if (_confirmPin != _firstPin) {
        setState(() {
          _errorMessage = 'PINs do not match. Try again.';
          _confirmPin = '';
        });
        return;
      }

      final success = await _pinService.setupPin(_firstPin);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vault PIN successfully created!'),
            backgroundColor: AppTheme.vaultAccentGreen,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.vaultHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: AppTheme.vaultBg,
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Setup Vault' : 'Change PIN'),
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.vaultAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppTheme.vaultAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isConfirming ? 'Confirm your Secret PIN' : 'Create your Secret PIN',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _isConfirming
                  ? 'Re-enter the same PIN to confirm'
                  : 'Enter 4 to 8 digits. Type this PIN into the calculator and press "=" to open your secret vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Pin indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                currentPin.length.clamp(4, 8),
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: index < currentPin.length
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
            // Numeric Keypad
            _buildKeypad(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: currentPin.length >= 4 ? _onNextOrConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vaultAccent,
                    disabledBackgroundColor: AppTheme.vaultBorder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isConfirming ? 'Save PIN & Enter Vault' : 'Next',
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
            onTap: () => _onNumberTap(val),
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
