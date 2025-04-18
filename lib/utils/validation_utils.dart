import 'package:flutter/material.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

class ValidationUtils {
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Validation error messages
  final Map<String, String> _validationErrors = {};
  
  // Singleton pattern
  static final ValidationUtils _instance = ValidationUtils._internal();
  
  factory ValidationUtils() {
    return _instance;
  }
  
  ValidationUtils._internal();
  
  // Validate email
  bool validateEmail(String email, {String? fieldName}) {
    final fieldKey = fieldName ?? 'email';
    
    try {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      
      if (email.isEmpty) {
        _validationErrors[fieldKey] = 'Email address is required';
        return false;
      }
      
      if (!emailRegex.hasMatch(email)) {
        _validationErrors[fieldKey] = 'Please enter a valid email address';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Email validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Email validation failed';
      return false;
    }
  }
  
  // Validate password
  bool validatePassword(String password, {String? fieldName, bool requireStrong = true}) {
    final fieldKey = fieldName ?? 'password';
    
    try {
      if (password.isEmpty) {
        _validationErrors[fieldKey] = 'Password is required';
        return false;
      }
      
      if (password.length < 8) {
        _validationErrors[fieldKey] = 'Password must be at least 8 characters long';
        return false;
      }
      
      if (requireStrong) {
        final hasUppercase = password.contains(RegExp(r'[A-Z]'));
        final hasLowercase = password.contains(RegExp(r'[a-z]'));
        final hasDigit = password.contains(RegExp(r'[0-9]'));
        final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
        
        if (!hasUppercase || !hasLowercase || !hasDigit || !hasSpecialChar) {
          _validationErrors[fieldKey] = 'Password must contain uppercase, lowercase, digit, and special character';
          return false;
        }
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Password validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Password validation failed';
      return false;
    }
  }
  
  // Validate PIN
  bool validatePin(String pin, {String? fieldName, int length = 4}) {
    final fieldKey = fieldName ?? 'pin';
    
    try {
      final pinRegex = RegExp(r'^\d+$');
      
      if (pin.isEmpty) {
        _validationErrors[fieldKey] = 'PIN is required';
        return false;
      }
      
      if (pin.length != length) {
        _validationErrors[fieldKey] = 'PIN must be $length digits';
        return false;
      }
      
      if (!pinRegex.hasMatch(pin)) {
        _validationErrors[fieldKey] = 'PIN must contain only digits';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'PIN validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'PIN validation failed';
      return false;
    }
  }
  
  // Validate name
  bool validateName(String name, {String? fieldName}) {
    final fieldKey = fieldName ?? 'name';
    
    try {
      if (name.isEmpty) {
        _validationErrors[fieldKey] = 'Name is required';
        return false;
      }
      
      if (name.length < 2) {
        _validationErrors[fieldKey] = 'Name must be at least 2 characters long';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Name validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Name validation failed';
      return false;
    }
  }
  
  // Validate phone number
  bool validatePhoneNumber(String phoneNumber, {String? fieldName}) {
    final fieldKey = fieldName ?? 'phoneNumber';
    
    try {
      // استخدام تعبير منتظم للتحقق من صحة رقم الهاتف
      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      
      if (phoneNumber.isEmpty) {
        _validationErrors[fieldKey] = 'Phone number is required';
        return false;
      }
      
      if (!phoneRegex.hasMatch(phoneNumber)) {
        _validationErrors[fieldKey] = 'Please enter a valid phone number';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Phone number validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Phone number validation failed';
      return false;
    }
  }
  
  // Validate amount
  bool validateAmount(String amount, {String? fieldName, double? minAmount, double? maxAmount}) {
    final fieldKey = fieldName ?? 'amount';
    
    try {
      if (amount.isEmpty) {
        _validationErrors[fieldKey] = 'Amount is required';
        return false;
      }
      
      final amountValue = double.tryParse(amount);
      
      if (amountValue == null) {
        _validationErrors[fieldKey] = 'Please enter a valid amount';
        return false;
      }
      
      if (amountValue <= 0) {
        _validationErrors[fieldKey] = 'Amount must be greater than zero';
        return false;
      }
      
      if (minAmount != null && amountValue < minAmount) {
        _validationErrors[fieldKey] = 'Amount must be at least $minAmount';
        return false;
      }
      
      if (maxAmount != null && amountValue > maxAmount) {
        _validationErrors[fieldKey] = 'Amount cannot exceed $maxAmount';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Amount validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Amount validation failed';
      return false;
    }
  }
  
  // Validate wallet address
  bool validateWalletAddress(String address, {String? fieldName, String? walletType}) {
    final fieldKey = fieldName ?? 'walletAddress';
    
    try {
      if (address.isEmpty) {
        _validationErrors[fieldKey] = 'Wallet address is required';
        return false;
      }
      
      // Validate based on wallet type
      if (walletType != null) {
        switch (walletType) {
          case 'USDT_TRC20':
            // TRC20 addresses start with T and are 34 characters long
            if (!address.startsWith('T') || address.length != 34) {
              _validationErrors[fieldKey] = 'Invalid TRC20 wallet address';
              return false;
            }
            break;
          case 'USDT_ERC20':
          case 'ETH':
            // ERC20 addresses start with 0x and are 42 characters long
            if (!address.startsWith('0x') || address.length != 42) {
              _validationErrors[fieldKey] = 'Invalid ERC20 wallet address';
              return false;
            }
            break;
          case 'BTC':
            // BTC addresses are between 26-35 characters
            if (address.length < 26 || address.length > 35) {
              _validationErrors[fieldKey] = 'Invalid Bitcoin wallet address';
              return false;
            }
            break;
          default:
            // Generic validation for other wallet types
            if (address.length < 20) {
              _validationErrors[fieldKey] = 'Invalid wallet address';
              return false;
            }
        }
      } else {
        // Generic validation if wallet type is not specified
        if (address.length < 20) {
          _validationErrors[fieldKey] = 'Invalid wallet address';
          return false;
        }
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Wallet address validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Wallet address validation failed';
      return false;
    }
  }
  
  // Validate required field
  bool validateRequired(String value, {required String fieldName}) {
    try {
      if (value.isEmpty) {
        _validationErrors[fieldName] = '$fieldName is required';
        return false;
      }
      
      _validationErrors.remove(fieldName);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Required field validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldName] = '$fieldName validation failed';
      return false;
    }
  }
  
  // Validate date
  bool validateDate(String date, {String? fieldName}) {
    final fieldKey = fieldName ?? 'date';
    
    try {
      if (date.isEmpty) {
        _validationErrors[fieldKey] = 'Date is required';
        return false;
      }
      
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      
      if (!dateRegex.hasMatch(date)) {
        _validationErrors[fieldKey] = 'Date must be in YYYY-MM-DD format';
        return false;
      }
      
      final dateTime = DateTime.tryParse(date);
      
      if (dateTime == null) {
        _validationErrors[fieldKey] = 'Please enter a valid date';
        return false;
      }
      
      _validationErrors.remove(fieldKey);
      return true;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Date validation error',
        ErrorSeverity.low,
      );
      
      _validationErrors[fieldKey] = 'Date validation failed';
      return false;
    }
  }
  
  // Validate form
  bool validateForm(Map<String, String> formData, Map<String, String> validationRules) {
    bool isValid = true;
    
    try {
      for (final entry in validationRules.entries) {
        final fieldName = entry.key;
        final validationType = entry.value;
        final fieldValue = formData[fieldName] ?? '';
        
        bool fieldValid = false;
        
        switch (validationType) {
          case 'email':
            fieldValid = validateEmail(fieldValue, fieldName: fieldName);
            break;
          case 'password':
            fieldValid = validatePassword(fieldValue, fieldName: fieldName);
            break;
          case 'pin':
            fieldValid = validatePin(fieldValue, fieldName: fieldName);
            break;
          case 'name':
            fieldValid = validateName(fieldValue, fieldName: fieldName);
            break;
          case 'phone':
            fieldValid = validatePhoneNumber(fieldValue, fieldName: fieldName);
            break;
          case 'amount':
            fieldValid = validateAmount(fieldValue, fieldName: fieldName);
            break;
          case 'walletAddress':
            fieldValid = validateWalletAddress(fieldValue, fieldName: fieldName);
            break;
          case 'required':
            fieldValid = validateRequired(fieldValue, fieldName: fieldName);
            break;
          case 'date':
            fieldValid = validateDate(fieldValue, fieldName: fieldName);
            break;
          default:
            // Default to required validation
            fieldValid = validateRequired(fieldValue, fieldName: fieldName);
        }
        
        if (!fieldValid) {
          isValid = false;
        }
      }
      
      return isValid;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Form validation error',
        ErrorSeverity.medium,
      );
      
      return false;
    }
  }
  
  // Get validation error for field
  String? getValidationError(String fieldName) {
    return _validationErrors[fieldName];
  }
  
  // Get all validation errors
  Map<String, String> getAllValidationErrors() {
    return Map.from(_validationErrors);
  }
  
  // Clear validation errors
  void clearValidationErrors() {
    _validationErrors.clear();
  }
  
  // Clear validation error for field
  void clearValidationError(String fieldName) {
    _validationErrors.remove(fieldName);
  }
  
  // Check if field has validation error
  bool hasValidationError(String fieldName) {
    return _validationErrors.containsKey(fieldName);
  }
  
  // Check if any validation errors exist
  bool hasAnyValidationErrors() {
    return _validationErrors.isNotEmpty;
  }
  
  // Get validation error count
  int getValidationErrorCount() {
    return _validationErrors.length;
  }
  
  // Get formatted validation error message
  String getFormattedValidationErrors() {
    if (_validationErrors.isEmpty) {
      return '';
    }
    
    return _validationErrors.values.join('\n');
  }
}
