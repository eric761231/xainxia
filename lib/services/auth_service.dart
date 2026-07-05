import 'dart:async';

import '../config/server_connection_loader.dart';
import '../network/packets/client/c_auth_login.dart';
import '../network/packets/client/c_auth_logout.dart';
import '../network/packets/server/s_login_result.dart';
import '../network/packets/server/s_logout_result.dart';
import 'game_session_service.dart';

/// 登入流程結果
class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.loginResult,
  });

  final bool success;
  final String message;
  final SLoginResult? loginResult;
}

/// 登出流程結果
class LogoutResult {
  const LogoutResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

/// 認證與登入；成功後 Socket 交由 [GameSessionService] 持續監聽。
class AuthService {
  AuthService(this._connectionConfig, this._session);

  final ServerConnectionConfig _connectionConfig;
  final GameSessionService _session;

  GameSessionService get session => _session;

  Future<AuthResult> login({
    required String account,
    required String password,
    required String serverName,
  }) async {
    final server = _connectionConfig.findByName(serverName);
    if (server == null) {
      return const AuthResult(success: false, message: '找不到伺服器設定');
    }

    try {
      await _session.connect(host: server.host, port: server.port);
    } catch (e) {
      await _session.disconnect();
      return AuthResult(success: false, message: '無法連線伺服器：$e');
    }

    final completer = Completer<SLoginResult>();
    _session.dispatcher.onLoginResult = (result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    };

    try {
      _session.send(CAuthLogin.build(account: account, password: password));
      final result = await completer.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待登入回應逾時'),
      );
      _session.dispatcher.onLoginResult = null;

      if (result.success) {
        _session.markAuthenticated();
        return AuthResult(
          success: true,
          message: result.message,
          loginResult: result,
        );
      }

      await _session.disconnect();
      return AuthResult(
        success: false,
        message: result.message,
        loginResult: result,
      );
    } on TimeoutException {
      await _session.disconnect();
      return const AuthResult(success: false, message: '伺服器回應逾時');
    } catch (e) {
      await _session.disconnect();
      return AuthResult(success: false, message: '登入失敗：$e');
    } finally {
      _session.dispatcher.onLoginResult = null;
    }
  }

  Future<LogoutResult> logout() async {
    if (!_session.isConnected) {
      return const LogoutResult(success: true, message: '已離線');
    }

    final completer = Completer<SLogoutResult>();
    _session.dispatcher.onLogoutResult = (result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    };

    try {
      _session.send(CAuthLogout.build());
      final result = await completer.future.timeout(
        Duration(milliseconds: _connectionConfig.packetTimeoutMs),
        onTimeout: () => throw TimeoutException('等待登出回應逾時'),
      );

      if (result.success) {
        return LogoutResult(
          success: true,
          message: result.message.isNotEmpty ? result.message : '登出成功',
        );
      }

      return LogoutResult(
        success: false,
        message: result.message.isNotEmpty ? result.message : '登出失敗',
      );
    } on TimeoutException {
      return const LogoutResult(success: false, message: '登出回應逾時');
    } catch (e) {
      return LogoutResult(success: false, message: '登出失敗：$e');
    } finally {
      _session.dispatcher.onLogoutResult = null;
      _session.markUnauthenticated();
      await _session.disconnect();
    }
  }

  Future<void> disconnect() => _session.disconnect();
}
