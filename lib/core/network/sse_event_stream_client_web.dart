import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:sakuramedia/core/network/api_client.dart';
import 'package:sakuramedia/core/network/api_error_dto.dart';
import 'package:sakuramedia/core/network/api_exception.dart';
import 'package:sakuramedia/core/network/api_sse_event.dart';
import 'package:sakuramedia/core/network/sse_decoder.dart';
import 'package:sakuramedia/core/network/sse_event_stream_client.dart';
import 'package:sakuramedia/core/session/session_store.dart';
import 'package:web/web.dart'
    as web
    show
        AbortController,
        DOMException,
        HeadersInit,
        ReadableStreamDefaultReader,
        ReadableStreamReadResult,
        RequestInfo,
        RequestInit,
        Response;

@JS('fetch')
external JSPromise<web.Response> _fetch(
  web.RequestInfo input, [
  web.RequestInit init,
]);

SseEventStreamClient createPlatformSseEventStreamClient({
  required ApiClient apiClient,
  required SessionStore sessionStore,
}) {
  return _WebSseEventStreamClient(sessionStore: sessionStore);
}

class _WebSseEventStreamClient implements SseEventStreamClient {
  _WebSseEventStreamClient({required SessionStore sessionStore})
    : _sessionStore = sessionStore;

  final SessionStore _sessionStore;
  final List<web.AbortController> _openRequestAbortControllers =
      <web.AbortController>[];
  bool _isDisposed = false;

  @override
  Stream<ApiSseEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async* {
    if (_isDisposed) {
      throw const SseEventStreamUnsupportedException('stream client closed');
    }
    if (_sessionStore.baseUrl.isEmpty || _sessionStore.accessToken.isEmpty) {
      throw ApiException.unauthorized(
        code: 'unauthorized',
        message: 'Event stream requires an authenticated session',
      );
    }

    final requestUri = _buildStreamUri(path, queryParameters);
    final abortController = web.AbortController();
    _openRequestAbortControllers.add(abortController);
    try {
      final response =
          await _fetch(
            requestUri.toString().toJS,
            web.RequestInit(
              method: 'GET',
              credentials: 'same-origin',
              headers:
                  <String, String>{
                        'Accept': 'text/event-stream',
                        'Authorization': 'Bearer ${_sessionStore.accessToken}',
                      }.jsify()
                      as web.HeadersInit,
              signal: abortController.signal,
            ),
          ).toDart;

      if (response.status >= 400) {
        final body = (await response.text().toDart).toDart;
        throw _mapErrorResponse(response.status, body);
      }

      final bodyStream = response.body;
      if (bodyStream == null) {
        throw const SseEventStreamUnsupportedException(
          'ReadableStream is unavailable in the current browser environment',
        );
      }

      yield* _bodyToStream(
        response,
        abortController,
        requestUri,
      ).transform(const SseDecoder());
    } finally {
      _openRequestAbortControllers.remove(abortController);
    }
  }

  @override
  void dispose() {
    for (final controller in _openRequestAbortControllers) {
      controller.abort();
    }
    _openRequestAbortControllers.clear();
    _isDisposed = true;
  }

  Uri _buildStreamUri(String path, Map<String, dynamic>? queryParameters) {
    final baseUrl = _sessionStore.baseUrl.trim();
    final normalizedBaseUrl =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBaseUrl$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final stringified = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) {
        return;
      }
      stringified[key] = value.toString();
    });
    if (stringified.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: stringified);
  }

  ApiException _mapErrorResponse(int statusCode, String body) {
    final decoded = _tryDecodeJson(body);
    final payload = _extractErrorPayload(decoded);
    return ApiException(
      statusCode: statusCode,
      message: payload?.message ?? 'Request failed',
      error: payload,
    );
  }

  dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  ApiErrorDto? _extractErrorPayload(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final rawError = value['error'];
    if (rawError is! Map) {
      return null;
    }
    return ApiErrorDto.fromJson(
      rawError.map(
        (dynamic key, dynamic data) => MapEntry(key.toString(), data),
      ),
    );
  }

  Stream<Uint8List> _bodyToStream(
    web.Response response,
    web.AbortController abortController,
    Uri requestUri,
  ) {
    return Stream<Uint8List>.multi(
      (controller) => _readStreamBody(
        requestUri: requestUri,
        response: response,
        abortController: abortController,
        controller: controller,
      ),
    );
  }

  Future<void> _readStreamBody({
    required Uri requestUri,
    required web.Response response,
    required web.AbortController abortController,
    required MultiStreamController<Uint8List> controller,
  }) async {
    final reader =
        response.body?.getReader() as web.ReadableStreamDefaultReader?;
    if (reader == null) {
      controller.addError(
        const SseEventStreamUnsupportedException(
          'ReadableStream reader is unavailable in the current browser environment',
        ),
      );
      await controller.close();
      return;
    }

    Completer<void>? resumeSignal;
    var cancelled = false;
    var hadError = false;
    controller
      ..onResume = () {
        if (resumeSignal case final resume?) {
          resumeSignal = null;
          resume.complete();
        }
      }
      ..onCancel = () async {
        cancelled = true;
        abortController.abort();
        try {
          await reader.cancel().toDart;
        } catch (_) {
          // Ignore cancellation errors from an already-closed stream.
        }
      };

    while (true) {
      final web.ReadableStreamReadResult chunk;
      try {
        chunk = await reader.read().toDart;
      } catch (error, stackTrace) {
        if (!cancelled) {
          hadError = true;
          controller.addError(_mapReaderError(error, requestUri), stackTrace);
          await controller.close();
        }
        break;
      }

      if (chunk.done) {
        controller.closeSync();
        break;
      }

      controller.addSync((chunk.value! as JSUint8Array).toDart);

      if (controller.isPaused) {
        await (resumeSignal ??= Completer<void>()).future;
      }
      if (!controller.hasListener) {
        break;
      }
    }

    if (!hadError && cancelled && controller.hasListener) {
      await controller.close();
    }
  }

  Object _mapReaderError(Object error, Uri requestUri) {
    if (error case web.DOMException(name: 'AbortError')) {
      return ApiException(message: 'Event stream aborted', statusCode: null);
    }
    if (error is ApiException ||
        error is SseEventStreamUnsupportedException) {
      return error;
    }
    return ApiException(message: error.toString());
  }
}
