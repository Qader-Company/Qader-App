import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/base_state.dart';
import '../resources/color_manager.dart';
import 'default_error.dart';
import 'default_loading.dart';

/// A wrapper widget that handles loading, error, empty, and success states
/// for paginated lists using [BaseState].
class PaginatedListWrapper<T, C extends Cubit<BaseState<T>>>
    extends StatelessWidget {
  final Widget Function(List<T> items) onSuccess;
  final Widget? onEmpty;
  final Widget? onLoading;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;
  final VoidCallback? onLoadMore;

  const PaginatedListWrapper({
    super.key,
    required this.onSuccess,
    this.onEmpty,
    this.onLoading,
    this.onRetry,
    this.scrollController,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, BaseState<T>>(
      builder: (context, state) {
        if (state.isLoading) {
          return onLoading ?? const DefaultLoading();
        }

        if (state.isFailure) {
          return DefaultError(
            message: state.errorMessage ?? 'Error',
            onRetry: onRetry,
          );
        }

        if (state.isEmpty) {
          return onEmpty ??
              Center(
                child: Text(
                  'No data found',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ColorManager.greyText,
                  ),
                ),
              );
        }

        return Column(
          children: [
            Expanded(child: onSuccess(state.items)),
            if (state.isLoadingMore)
              Padding(
                padding: EdgeInsets.all(8.h),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        );
      },
    );
  }
}
