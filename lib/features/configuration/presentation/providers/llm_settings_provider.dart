import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sakuramedia/core/network/providers/api_client_provider.dart';
import 'package:sakuramedia/core/network/api_error_message.dart';
import 'package:sakuramedia/features/configuration/data/api/movie_desc_translation_settings_api.dart';
import 'package:sakuramedia/features/configuration/data/dto/movie_desc_translation_settings_dto.dart';
import 'package:sakuramedia/features/configuration/presentation/providers/llm_settings_state.dart';
import 'package:sakuramedia/features/shared/presentation/providers/async_notifier_dispose_guard.dart';

part 'llm_settings_provider.g.dart';

@Riverpod(keepAlive: true)
MovieDescTranslationSettingsApi llmSettingsApi(Ref ref) {
  return MovieDescTranslationSettingsApi(
    apiClient: ref.watch(apiClientProvider),
  );
}

@Riverpod(keepAlive: true, retry: kNoAsyncNotifierRetry)
class LlmSettings extends _$LlmSettings
    with AsyncNotifierDisposeGuardMixin<LlmSettingsState> {
  @override
  Future<LlmSettingsState> build() async {
    attachDisposeGuard();
    final settings = await ref.read(llmSettingsApiProvider).getSettings();
    return LlmSettingsState.fromDto(settings);
  }

  Future<void> reload() async {
    state = const AsyncLoading<LlmSettingsState>();
    final nextState = await AsyncValue.guard(() async {
      final settings = await ref.read(llmSettingsApiProvider).getSettings();
      return LlmSettingsState.fromDto(settings);
    });
    if (!isDisposed) {
      state = nextState;
    }
  }

  Future<String?> refresh() async {
    final current = state.value;
    if (current == null) {
      await reload();
      return null;
    }
    try {
      final settings = await ref.read(llmSettingsApiProvider).getSettings();
      if (!isDisposed) {
        state = AsyncData(LlmSettingsState.fromDto(settings));
      }
      return null;
    } catch (error) {
      return apiErrorMessage(error, fallback: 'LLM 配置加载失败');
    }
  }

  void updateDraft(LlmSettingsDraft draft) {
    final current = state.value;
    if (current == null || !current.fieldsEnabled || current.draft == draft) {
      return;
    }
    state = AsyncData(
      current.copyWith(draft: draft, testState: LlmConfigTestState.idle),
    );
  }

  Future<String?> save() async {
    final current = state.value;
    if (current == null || current.isSaving || current.isTesting) {
      return null;
    }
    if (!isValidLlmDraft(current.draft)) {
      state = AsyncData(current.copyWith(showValidation: true));
      return null;
    }

    state = AsyncData(current.copyWith(isSaving: true));
    try {
      final saved = await ref
          .read(llmSettingsApiProvider)
          .updateSettings(_buildUpdatePayload(current.draft));
      if (isDisposed) {
        return null;
      }
      final savedDraft = LlmSettingsDraft.fromDto(saved);
      state = AsyncData(
        current.copyWith(
          saved: savedDraft,
          draft: savedDraft,
          isSaving: false,
          showValidation: false,
          testState: LlmConfigTestState.idle,
        ),
      );
      return 'LLM 配置已保存';
    } catch (error) {
      if (!isDisposed) {
        state = AsyncData(current.copyWith(isSaving: false));
      }
      return apiErrorMessage(error, fallback: '保存 LLM 配置失败');
    }
  }

  Future<String?> runConnectionTest() async {
    final current = state.value;
    if (current == null || current.isSaving || current.isTesting) {
      return null;
    }
    if (!isValidLlmDraft(current.draft)) {
      state = AsyncData(current.copyWith(showValidation: true));
      return null;
    }

    state = AsyncData(current.copyWith(isTesting: true));
    try {
      final ok = await ref
          .read(llmSettingsApiProvider)
          .testSettings(_buildTestPayload(current.draft));
      if (isDisposed) {
        return null;
      }
      state = AsyncData(
        current.copyWith(
          isTesting: false,
          testState:
              ok ? LlmConfigTestState.success : LlmConfigTestState.failure,
        ),
      );
      return ok ? '测试通过' : '测试失败';
    } catch (error) {
      if (!isDisposed) {
        state = AsyncData(
          current.copyWith(
            isTesting: false,
            testState: LlmConfigTestState.failure,
          ),
        );
      }
      return apiErrorMessage(error, fallback: '测试 LLM 配置失败');
    }
  }
}

UpdateMovieDescTranslationSettingsPayload _buildUpdatePayload(
  LlmSettingsDraft draft,
) {
  return UpdateMovieDescTranslationSettingsPayload(
    enabled: draft.enabled,
    baseUrl: draft.baseUrl.trim(),
    apiKey: draft.apiKey,
    model: draft.model.trim(),
    timeoutSeconds: double.parse(draft.timeoutSeconds.trim()),
    connectTimeoutSeconds: double.parse(draft.connectTimeoutSeconds.trim()),
  );
}

TestMovieDescTranslationSettingsPayload _buildTestPayload(
  LlmSettingsDraft draft,
) {
  return TestMovieDescTranslationSettingsPayload(
    enabled: draft.enabled,
    baseUrl: draft.baseUrl.trim(),
    apiKey: draft.apiKey,
    model: draft.model.trim(),
    timeoutSeconds: double.parse(draft.timeoutSeconds.trim()),
    connectTimeoutSeconds: double.parse(draft.connectTimeoutSeconds.trim()),
  );
}
