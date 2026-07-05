/// 帳密輸入驗證，規則對齊伺服端 [C_AuthLogin]。
class AuthInputValidator {
  AuthInputValidator._();

  static const _allowedAccountChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  static const _allowedPasswordChars =
      'abcdefghijklmnopqrstuvwxyz0123456789!_=+-?.#';

  static String? validateAccount(String account) {
    final value = account.trim().toLowerCase();
    if (value.isEmpty) {
      return '請輸入帳號';
    }
    if (value.length < 4 || value.length > 12) {
      return '帳號長度需為 4～12 字元';
    }
    for (final rune in value.runes) {
      final ch = String.fromCharCode(rune);
      if (!_allowedAccountChars.contains(ch)) {
        return '帳號只能使用小寫英文字母與數字';
      }
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return '請輸入密碼';
    }
    if (password.length < 4 || password.length > 13) {
      return '密碼長度需為 4～13 字元';
    }
    for (final rune in password.runes) {
      final ch = String.fromCharCode(rune).toLowerCase();
      if (!_allowedPasswordChars.contains(ch)) {
        return '密碼包含不允許的字元';
      }
    }
    return null;
  }
}
