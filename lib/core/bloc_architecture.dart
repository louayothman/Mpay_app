import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base class for all BLoC events
/// Events are the input to a BLoC. They're commonly UI events, such as button presses.
abstract class BlocEvent {
  const BlocEvent();
}

/// Base class for all BLoC states
/// States are the output of a BLoC. They represent the state of the UI.
abstract class BlocState {
  const BlocState();
}

/// Base class for all BLoCs
/// BLoC (Business Logic Component) separates business logic from UI
abstract class BaseBloc<Event extends BlocEvent, State extends BlocState> extends Bloc<Event, State> {
  BaseBloc(State initialState) : super(initialState);
  
  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
    // Log transitions for debugging
    debugPrint('BLoC Transition: $transition');
  }
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    // Log errors for debugging
    debugPrint('BLoC Error: $error');
    debugPrint('StackTrace: $stackTrace');
  }
}

/// A mixin that provides common functionality for BLoCs
mixin BlocLoggerMixin<Event extends BlocEvent, State extends BlocState> on Bloc<Event, State> {
  @override
  void onEvent(Event event) {
    super.onEvent(event);
    // Log events for debugging
    debugPrint('BLoC Event: $event');
  }
  
  @override
  void onTransition(Transition<Event, State> transition) {
    super.onTransition(transition);
    // Log transitions for debugging
    debugPrint('BLoC Transition: $transition');
  }
  
  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    // Log errors for debugging
    debugPrint('BLoC Error: $error');
    debugPrint('StackTrace: $stackTrace');
  }
}

/// A BLoC provider widget that provides a BLoC to its children
class BlocProviderWidget<B extends Bloc<dynamic, dynamic>> extends StatelessWidget {
  final B Function(BuildContext) create;
  final Widget child;
  final bool lazy;
  
  const BlocProviderWidget({
    Key? key,
    required this.create,
    required this.child,
    this.lazy = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider<B>(
      create: create,
      lazy: lazy,
      child: child,
    );
  }
}

/// A multi-BLoC provider widget that provides multiple BLoCs to its children
class MultiBlocProviderWidget extends StatelessWidget {
  final List<BlocProviderSingleChildWidget> providers;
  final Widget child;
  
  const MultiBlocProviderWidget({
    Key? key,
    required this.providers,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: providers,
      child: child,
    );
  }
}

/// A BLoC consumer widget that rebuilds when the BLoC state changes
class BlocConsumerWidget<B extends Bloc<dynamic, S>, S> extends StatelessWidget {
  final Widget Function(BuildContext context, S state) builder;
  final void Function(BuildContext context, S state)? listener;
  final S? listenWhen;
  final bool Function(S previous, S current)? buildWhen;
  
  const BlocConsumerWidget({
    Key? key,
    required this.builder,
    this.listener,
    this.listenWhen,
    this.buildWhen,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, S>(
      listener: listener ?? (_, __) {},
      builder: builder,
      buildWhen: buildWhen,
      listenWhen: listenWhen != null ? (_, current) => current == listenWhen : null,
    );
  }
}

/// A BLoC builder widget that rebuilds when the BLoC state changes
class BlocBuilderWidget<B extends Bloc<dynamic, S>, S> extends StatelessWidget {
  final Widget Function(BuildContext context, S state) builder;
  final bool Function(S previous, S current)? buildWhen;
  
  const BlocBuilderWidget({
    Key? key,
    required this.builder,
    this.buildWhen,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      builder: builder,
      buildWhen: buildWhen,
    );
  }
}

/// A BLoC listener widget that executes a callback when the BLoC state changes
class BlocListenerWidget<B extends Bloc<dynamic, S>, S> extends StatelessWidget {
  final void Function(BuildContext context, S state) listener;
  final bool Function(S previous, S current)? listenWhen;
  final Widget child;
  
  const BlocListenerWidget({
    Key? key,
    required this.listener,
    required this.child,
    this.listenWhen,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }
}

/// A multi-BLoC listener widget that executes callbacks when multiple BLoC states change
class MultiBlocListenerWidget extends StatelessWidget {
  final List<BlocListenerSingleChildWidget> listeners;
  final Widget child;
  
  const MultiBlocListenerWidget({
    Key? key,
    required this.listeners,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: listeners,
      child: child,
    );
  }
}

/// A BLoC selector widget that rebuilds when a specific part of the BLoC state changes
class BlocSelectorWidget<B extends Bloc<dynamic, S>, S, T> extends StatelessWidget {
  final T Function(S state) selector;
  final Widget Function(BuildContext context, T value) builder;
  
  const BlocSelectorWidget({
    Key? key,
    required this.selector,
    required this.builder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocSelector<B, S, T>(
      selector: selector,
      builder: builder,
    );
  }
}

/// A repository provider widget that provides a repository to its children
class RepositoryProviderWidget<T> extends StatelessWidget {
  final T Function(BuildContext) create;
  final Widget child;
  final bool lazy;
  
  const RepositoryProviderWidget({
    Key? key,
    required this.create,
    required this.child,
    this.lazy = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<T>(
      create: create,
      lazy: lazy,
      child: child,
    );
  }
}

/// A multi-repository provider widget that provides multiple repositories to its children
class MultiRepositoryProviderWidget extends StatelessWidget {
  final List<RepositoryProviderSingleChildWidget> providers;
  final Widget child;
  
  const MultiRepositoryProviderWidget({
    Key? key,
    required this.providers,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: providers,
      child: child,
    );
  }
}

/// A base class for all BLoC events related to loading data
abstract class LoadEvent extends BlocEvent {
  const LoadEvent();
}

/// A base class for all BLoC events related to refreshing data
abstract class RefreshEvent extends BlocEvent {
  const RefreshEvent();
}

/// A base class for all BLoC events related to creating data
abstract class CreateEvent<T> extends BlocEvent {
  final T data;
  
  const CreateEvent(this.data);
}

/// A base class for all BLoC events related to updating data
abstract class UpdateEvent<T> extends BlocEvent {
  final String id;
  final T data;
  
  const UpdateEvent(this.id, this.data);
}

/// A base class for all BLoC events related to deleting data
abstract class DeleteEvent extends BlocEvent {
  final String id;
  
  const DeleteEvent(this.id);
}

/// A base class for all BLoC states related to initial state
abstract class InitialState extends BlocState {
  const InitialState();
}

/// A base class for all BLoC states related to loading state
abstract class LoadingState extends BlocState {
  const LoadingState();
}

/// A base class for all BLoC states related to loaded state
abstract class LoadedState<T> extends BlocState {
  final T data;
  
  const LoadedState(this.data);
}

/// A base class for all BLoC states related to error state
abstract class ErrorState extends BlocState {
  final String message;
  
  const ErrorState(this.message);
}

/// A base class for all BLoC states related to empty state
abstract class EmptyState extends BlocState {
  const EmptyState();
}

/// A base class for all BLoC states related to creating state
abstract class CreatingState extends BlocState {
  const CreatingState();
}

/// A base class for all BLoC states related to created state
abstract class CreatedState<T> extends BlocState {
  final T data;
  
  const CreatedState(this.data);
}

/// A base class for all BLoC states related to updating state
abstract class UpdatingState extends BlocState {
  const UpdatingState();
}

/// A base class for all BLoC states related to updated state
abstract class UpdatedState<T> extends BlocState {
  final T data;
  
  const UpdatedState(this.data);
}

/// A base class for all BLoC states related to deleting state
abstract class DeletingState extends BlocState {
  const DeletingState();
}

/// A base class for all BLoC states related to deleted state
abstract class DeletedState extends BlocState {
  final String id;
  
  const DeletedState(this.id);
}

/// A base class for all BLoC states related to refreshing state
abstract class RefreshingState extends BlocState {
  const RefreshingState();
}

/// A base class for all BLoC states related to refreshed state
abstract class RefreshedState<T> extends BlocState {
  final T data;
  
  const RefreshedState(this.data);
}

/// A base class for all BLoC states related to processing state
abstract class ProcessingState extends BlocState {
  const ProcessingState();
}

/// A base class for all BLoC states related to processed state
abstract class ProcessedState<T> extends BlocState {
  final T data;
  
  const ProcessedState(this.data);
}

/// A base class for all BLoC states related to success state
abstract class SuccessState<T> extends BlocState {
  final T data;
  
  const SuccessState(this.data);
}

/// A base class for all BLoC states related to failure state
abstract class FailureState extends BlocState {
  final String message;
  
  const FailureState(this.message);
}

/// A base class for all BLoC states related to validation state
abstract class ValidationState extends BlocState {
  final List<String> errors;
  
  const ValidationState(this.errors);
  
  bool get isValid => errors.isEmpty;
}

/// A base class for all BLoC states related to authenticated state
abstract class AuthenticatedState extends BlocState {
  final String userId;
  
  const AuthenticatedState(this.userId);
}

/// A base class for all BLoC states related to unauthenticated state
abstract class UnauthenticatedState extends BlocState {
  const UnauthenticatedState();
}

/// A base class for all BLoC states related to authenticating state
abstract class AuthenticatingState extends BlocState {
  const AuthenticatingState();
}

/// A base class for all BLoC states related to authentication error state
abstract class AuthenticationErrorState extends BlocState {
  final String message;
  
  const AuthenticationErrorState(this.message);
}

/// A base class for all BLoC states related to authorization state
abstract class AuthorizedState extends BlocState {
  final List<String> permissions;
  
  const AuthorizedState(this.permissions);
}

/// A base class for all BLoC states related to unauthorized state
abstract class UnauthorizedState extends BlocState {
  const UnauthorizedState();
}

/// A base class for all BLoC states related to authorizing state
abstract class AuthorizingState extends BlocState {
  const AuthorizingState();
}

/// A base class for all BLoC states related to authorization error state
abstract class AuthorizationErrorState extends BlocState {
  final String message;
  
  const AuthorizationErrorState(this.message);
}

/// A base class for all BLoC states related to connection state
abstract class ConnectionState extends BlocState {
  final bool isConnected;
  
  const ConnectionState(this.isConnected);
}

/// A base class for all BLoC states related to online state
abstract class OnlineState extends BlocState {
  const OnlineState();
}

/// A base class for all BLoC states related to offline state
abstract class OfflineState extends BlocState {
  const OfflineState();
}

/// A base class for all BLoC states related to connecting state
abstract class ConnectingState extends BlocState {
  const ConnectingState();
}

/// A base class for all BLoC states related to connection error state
abstract class ConnectionErrorState extends BlocState {
  final String message;
  
  const ConnectionErrorState(this.message);
}

/// A base class for all BLoC states related to progress state
abstract class ProgressState extends BlocState {
  final double progress;
  
  const ProgressState(this.progress);
}

/// A base class for all BLoC states related to completed state
abstract class CompletedState extends BlocState {
  const CompletedState();
}

/// A base class for all BLoC states related to canceled state
abstract class CanceledState extends BlocState {
  const CanceledState();
}

/// A base class for all BLoC states related to paused state
abstract class PausedState extends BlocState {
  const PausedState();
}

/// A base class for all BLoC states related to resumed state
abstract class ResumedState extends BlocState {
  const ResumedState();
}

/// A base class for all BLoC states related to busy state
abstract class BusyState extends BlocState {
  const BusyState();
}

/// A base class for all BLoC states related to idle state
abstract class IdleState extends BlocState {
  const IdleState();
}

/// A base class for all BLoC states related to active state
abstract class ActiveState extends BlocState {
  const ActiveState();
}

/// A base class for all BLoC states related to inactive state
abstract class InactiveState extends BlocState {
  const InactiveState();
}

/// A base class for all BLoC states related to enabled state
abstract class EnabledState extends BlocState {
  const EnabledState();
}

/// A base class for all BLoC states related to disabled state
abstract class DisabledState extends BlocState {
  const DisabledState();
}

/// A base class for all BLoC states related to visible state
abstract class VisibleState extends BlocState {
  const VisibleState();
}

/// A base class for all BLoC states related to hidden state
abstract class HiddenState extends BlocState {
  const HiddenState();
}

/// A base class for all BLoC states related to expanded state
abstract class ExpandedState extends BlocState {
  const ExpandedState();
}

/// A base class for all BLoC states related to collapsed state
abstract class CollapsedState extends BlocState {
  const CollapsedState();
}

/// A base class for all BLoC states related to selected state
abstract class SelectedState<T> extends BlocState {
  final T selected;
  
  const SelectedState(this.selected);
}

/// A base class for all BLoC states related to unselected state
abstract class UnselectedState extends BlocState {
  const UnselectedState();
}

/// A base class for all BLoC states related to focused state
abstract class FocusedState extends BlocState {
  const FocusedState();
}

/// A base class for all BLoC states related to unfocused state
abstract class UnfocusedState extends BlocState {
  const UnfocusedState();
}

/// A base class for all BLoC states related to hovered state
abstract class HoveredState extends BlocState {
  const HoveredState();
}

/// A base class for all BLoC states related to unhovered state
abstract class UnhoveredState extends BlocState {
  const UnhoveredState();
}

/// A base class for all BLoC states related to pressed state
abstract class PressedState extends BlocState {
  const PressedState();
}

/// A base class for all BLoC states related to unpressed state
abstract class UnpressedState extends BlocState {
  const UnpressedState();
}

/// A base class for all BLoC states related to dragged state
abstract class DraggedState extends BlocState {
  const DraggedState();
}

/// A base class for all BLoC states related to undragged state
abstract class UndraggedState extends BlocState {
  const UndraggedState();
}

/// A base class for all BLoC states related to dropped state
abstract class DroppedState extends BlocState {
  const DroppedState();
}

/// A base class for all BLoC states related to undropped state
abstract class UndroppedState extends BlocState {
  const UndroppedState();
}

/// A base class for all BLoC states related to scrolled state
abstract class ScrolledState extends BlocState {
  final double offset;
  
  const ScrolledState(this.offset);
}

/// A base class for all BLoC states related to unscrolled state
abstract class UnscrolledState extends BlocState {
  const UnscrolledState();
}

/// A base class for all BLoC states related to zoomed state
abstract class ZoomedState extends BlocState {
  final double scale;
  
  const ZoomedState(this.scale);
}

/// A base class for all BLoC states related to unzoomed state
abstract class UnzoomedState extends BlocState {
  const UnzoomedState();
}

/// A base class for all BLoC states related to rotated state
abstract class RotatedState extends BlocState {
  final double angle;
  
  const RotatedState(this.angle);
}

/// A base class for all BLoC states related to unrotated state
abstract class UnrotatedState extends BlocState {
  const UnrotatedState();
}

/// A base class for all BLoC states related to flipped state
abstract class FlippedState extends BlocState {
  final bool horizontal;
  final bool vertical;
  
  const FlippedState({
    this.horizontal = false,
    this.vertical = false,
  });
}

/// A base class for all BLoC states related to unflipped state
abstract class UnflippedState extends BlocState {
  const UnflippedState();
}

/// A base class for all BLoC states related to animated state
abstract class AnimatedState extends BlocState {
  const AnimatedState();
}

/// A base class for all BLoC states related to unanimated state
abstract class UnanimatedState extends BlocState {
  const UnanimatedState();
}

/// A base class for all BLoC states related to transitioning state
abstract class TransitioningState extends BlocState {
  const TransitioningState();
}

/// A base class for all BLoC states related to untransitioning state
abstract class UntransitioningState extends BlocState {
  const UntransitioningState();
}

/// A base class for all BLoC states related to fading state
abstract class FadingState extends BlocState {
  final double opacity;
  
  const FadingState(this.opacity);
}

/// A base class for all BLoC states related to unfading state
abstract class UnfadingState extends BlocState {
  const UnfadingState();
}

/// A base class for all BLoC states related to sliding state
abstract class SlidingState extends BlocState {
  final Offset offset;
  
  const SlidingState(this.offset);
}

/// A base class for all BLoC states related to unsliding state
abstract class UnslidingState extends BlocState {
  const UnslidingState();
}

/// A base class for all BLoC states related to scaling state
abstract class ScalingState extends BlocState {
  final double scale;
  
  const ScalingState(this.scale);
}

/// A base class for all BLoC states related to unscaling state
abstract class UnscalingState extends BlocState {
  const UnscalingState();
}

/// A base class for all BLoC states related to rotating state
abstract class RotatingState extends BlocState {
  final double angle;
  
  const RotatingState(this.angle);
}

/// A base class for all BLoC states related to unrotating state
abstract class UnrotatingState extends BlocState {
  const UnrotatingState();
}

/// A base class for all BLoC states related to flipping state
abstract class FlippingState extends BlocState {
  final bool horizontal;
  final bool vertical;
  
  const FlippingState({
    this.horizontal = false,
    this.vertical = false,
  });
}

/// A base class for all BLoC states related to unflipping state
abstract class UnflippingState extends BlocState {
  const UnflippingState();
}

/// A base class for all BLoC states related to bouncing state
abstract class BouncingState extends BlocState {
  const BouncingState();
}

/// A base class for all BLoC states related to unbouncing state
abstract class UnbouncingState extends BlocState {
  const UnbouncingState();
}

/// A base class for all BLoC states related to pulsing state
abstract class PulsingState extends BlocState {
  const PulsingState();
}

/// A base class for all BLoC states related to unpulsing state
abstract class UnpulsingState extends BlocState {
  const UnpulsingState();
}

/// A base class for all BLoC states related to shaking state
abstract class ShakingState extends BlocState {
  const ShakingState();
}

/// A base class for all BLoC states related to unshaking state
abstract class UnshakingState extends BlocState {
  const UnshakingState();
}

/// A base class for all BLoC states related to vibrating state
abstract class VibratingState extends BlocState {
  const VibratingState();
}

/// A base class for all BLoC states related to unvibrating state
abstract class UnvibratingState extends BlocState {
  const UnvibratingState();
}

/// A base class for all BLoC states related to blinking state
abstract class BlinkingState extends BlocState {
  const BlinkingState();
}

/// A base class for all BLoC states related to unblinking state
abstract class UnblinkingState extends BlocState {
  const UnblinkingState();
}

/// A base class for all BLoC states related to flashing state
abstract class FlashingState extends BlocState {
  const FlashingState();
}

/// A base class for all BLoC states related to unflashing state
abstract class UnflashingState extends BlocState {
  const UnflashingState();
}

/// A base class for all BLoC states related to glowing state
abstract class GlowingState extends BlocState {
  const GlowingState();
}

/// A base class for all BLoC states related to unglowing state
abstract class UnglowingState extends BlocState {
  const UnglowingState();
}

/// A base class for all BLoC states related to rippling state
abstract class RipplingState extends BlocState {
  const RipplingState();
}

/// A base class for all BLoC states related to unrippling state
abstract class UnripplingState extends BlocState {
  const UnripplingState();
}

/// A base class for all BLoC states related to waving state
abstract class WavingState extends BlocState {
  const WavingState();
}

/// A base class for all BLoC states related to unwaving state
abstract class UnwavingState extends BlocState {
  const UnwavingState();
}

/// A base class for all BLoC states related to floating state
abstract class FloatingState extends BlocState {
  const FloatingState();
}

/// A base class for all BLoC states related to unfloating state
abstract class UnfloatingState extends BlocState {
  const UnfloatingState();
}

/// A base class for all BLoC states related to hovering state
abstract class HoveringState extends BlocState {
  const HoveringState();
}

/// A base class for all BLoC states related to unhovering state
abstract class UnhoveringState extends BlocState {
  const UnhoveringState();
}

/// A base class for all BLoC states related to swinging state
abstract class SwingingState extends BlocState {
  const SwingingState();
}

/// A base class for all BLoC states related to unswinging state
abstract class UnswingingState extends BlocState {
  const UnswingingState();
}

/// A base class for all BLoC states related to spinning state
abstract class SpinningState extends BlocState {
  const SpinningState();
}

/// A base class for all BLoC states related to unspinning state
abstract class UnspinningState extends BlocState {
  const UnspinningState();
}

/// A base class for all BLoC states related to twisting state
abstract class TwistingState extends BlocState {
  const TwistingState();
}

/// A base class for all BLoC states related to untwisting state
abstract class UntwistingState extends BlocState {
  const UntwistingState();
}

/// A base class for all BLoC states related to stretching state
abstract class StretchingState extends BlocState {
  const StretchingState();
}

/// A base class for all BLoC states related to unstretching state
abstract class UnstretchingState extends BlocState {
  const UnstretchingState();
}

/// A base class for all BLoC states related to squeezing state
abstract class SqueezingState extends BlocState {
  const SqueezingState();
}

/// A base class for all BLoC states related to unsqueezing state
abstract class UnsqueezingState extends BlocState {
  const UnsqueezingState();
}

/// A base class for all BLoC states related to expanding state
abstract class ExpandingState extends BlocState {
  const ExpandingState();
}

/// A base class for all BLoC states related to unexpanding state
abstract class UnexpandingState extends BlocState {
  const UnexpandingState();
}

/// A base class for all BLoC states related to collapsing state
abstract class CollapsingState extends BlocState {
  const CollapsingState();
}

/// A base class for all BLoC states related to uncollapsing state
abstract class UncollapsingState extends BlocState {
  const UncollapsingState();
}

/// A base class for all BLoC states related to folding state
abstract class FoldingState extends BlocState {
  const FoldingState();
}

/// A base class for all BLoC states related to unfolding state
abstract class UnfoldingState extends BlocState {
  const UnfoldingState();
}

/// A base class for all BLoC states related to unfolding state
abstract class UnfoldingState extends BlocState {
  const UnfoldingState();
}

/// A base class for all BLoC states related to rolling state
abstract class RollingState extends BlocState {
  const RollingState();
}

/// A base class for all BLoC states related to unrolling state
abstract class UnrollingState extends BlocState {
  const UnrollingState();
}

/// A base class for all BLoC states related to scrolling state
abstract class ScrollingState extends BlocState {
  const ScrollingState();
}

/// A base class for all BLoC states related to unscrolling state
abstract class UnscrollingState extends BlocState {
  const UnscrollingState();
}

/// A base class for all BLoC states related to zooming state
abstract class ZoomingState extends BlocState {
  const ZoomingState();
}

/// A base class for all BLoC states related to unzooming state
abstract class UnzoomingState extends BlocState {
  const UnzoomingState();
}

/// A base class for all BLoC states related to panning state
abstract class PanningState extends BlocState {
  const PanningState();
}

/// A base class for all BLoC states related to unpanning state
abstract class UnpanningState extends BlocState {
  const UnpanningState();
}

/// A base class for all BLoC states related to tilting state
abstract class TiltingState extends BlocState {
  const TiltingState();
}

/// A base class for all BLoC states related to untilting state
abstract class UntiltingState extends BlocState {
  const UntiltingState();
}

/// A base class for all BLoC states related to skewing state
abstract class SkewingState extends BlocState {
  const SkewingState();
}

/// A base class for all BLoC states related to unskewing state
abstract class UnskewingState extends BlocState {
  const UnskewingState();
}

/// A base class for all BLoC states related to warping state
abstract class WarpingState extends BlocState {
  const WarpingState();
}

/// A base class for all BLoC states related to unwarping state
abstract class UnwarpingState extends BlocState {
  const UnwarpingState();
}

/// A base class for all BLoC states related to distorting state
abstract class DistortingState extends BlocState {
  const DistortingState();
}

/// A base class for all BLoC states related to undistorting state
abstract class UndistortingState extends BlocState {
  const UndistortingState();
}

/// A base class for all BLoC states related to morphing state
abstract class MorphingState extends BlocState {
  const MorphingState();
}

/// A base class for all BLoC states related to unmorphing state
abstract class UnmorphingState extends BlocState {
  const UnmorphingState();
}

/// A base class for all BLoC states related to transforming state
abstract class TransformingState extends BlocState {
  const TransformingState();
}

/// A base class for all BLoC states related to untransforming state
abstract class UntransformingState extends BlocState {
  const UntransformingState();
}

/// A base class for all BLoC states related to animating state
abstract class AnimatingState extends BlocState {
  const AnimatingState();
}

/// A base class for all BLoC states related to unanimating state
abstract class UnanimatingState extends BlocState {
  const UnanimatingState();
}

/// A base class for all BLoC states related to transitioning state
abstract class TransitioningState extends BlocState {
  const TransitioningState();
}

/// A base class for all BLoC states related to untransitioning state
abstract class UntransitioningState extends BlocState {
  const UntransitioningState();
}

/// A base class for all BLoC states related to fading state
abstract class FadingState extends BlocState {
  const FadingState();
}

/// A base class for all BLoC states related to unfading state
abstract class UnfadingState extends BlocState {
  const UnfadingState();
}

/// A base class for all BLoC states related to sliding state
abstract class SlidingState extends BlocState {
  const SlidingState();
}

/// A base class for all BLoC states related to unsliding state
abstract class UnslidingState extends BlocState {
  const UnslidingState();
}

/// A base class for all BLoC states related to scaling state
abstract class ScalingState extends BlocState {
  const ScalingState();
}

/// A base class for all BLoC states related to unscaling state
abstract class UnscalingState extends BlocState {
  const UnscalingState();
}

/// A base class for all BLoC states related to rotating state
abstract class RotatingState extends BlocState {
  const RotatingState();
}

/// A base class for all BLoC states related to unrotating state
abstract class UnrotatingState extends BlocState {
  const UnrotatingState();
}

/// A base class for all BLoC states related to flipping state
abstract class FlippingState extends BlocState {
  const FlippingState();
}

/// A base class for all BLoC states related to unflipping state
abstract class UnflippingState extends BlocState {
  const UnflippingState();
}

/// A base class for all BLoC states related to bouncing state
abstract class BouncingState extends BlocState {
  const BouncingState();
}

/// A base class for all BLoC states related to unbouncing state
abstract class UnbouncingState extends BlocState {
  const UnbouncingState();
}

/// A base class for all BLoC states related to pulsing state
abstract class PulsingState extends BlocState {
  const PulsingState();
}

/// A base class for all BLoC states related to unpulsing state
abstract class UnpulsingState extends BlocState {
  const UnpulsingState();
}

/// A base class for all BLoC states related to shaking state
abstract class ShakingState extends BlocState {
  const ShakingState();
}

/// A base class for all BLoC states related to unshaking state
abstract class UnshakingState extends BlocState {
  const UnshakingState();
}

/// A base class for all BLoC states related to vibrating state
abstract class VibratingState extends BlocState {
  const VibratingState();
}

/// A base class for all BLoC states related to unvibrating state
abstract class UnvibratingState extends BlocState {
  const UnvibratingState();
}

/// A base class for all BLoC states related to blinking state
abstract class BlinkingState extends BlocState {
  const BlinkingState();
}

/// A base class for all BLoC states related to unblinking state
abstract class UnblinkingState extends BlocState {
  const UnblinkingState();
}

/// A base class for all BLoC states related to flashing state
abstract class FlashingState extends BlocState {
  const FlashingState();
}

/// A base class for all BLoC states related to unflashing state
abstract class UnflashingState extends BlocState {
  const UnflashingState();
}

/// A base class for all BLoC states related to glowing state
abstract class GlowingState extends BlocState {
  const GlowingState();
}

/// A base class for all BLoC states related to unglowing state
abstract class UnglowingState extends BlocState {
  const UnglowingState();
}

/// A base class for all BLoC states related to rippling state
abstract class RipplingState extends BlocState {
  const RipplingState();
}

/// A base class for all BLoC states related to unrippling state
abstract class UnripplingState extends BlocState {
  const UnripplingState();
}

/// A base class for all BLoC states related to waving state
abstract class WavingState extends BlocState {
  const WavingState();
}

/// A base class for all BLoC states related to unwaving state
abstract class UnwavingState extends BlocState {
  const UnwavingState();
}

/// A base class for all BLoC states related to floating state
abstract class FloatingState extends BlocState {
  const FloatingState();
}

/// A base class for all BLoC states related to unfloating state
abstract class UnfloatingState extends BlocState {
  const UnfloatingState();
}

/// A base class for all BLoC states related to hovering state
abstract class HoveringState extends BlocState {
  const HoveringState();
}

/// A base class for all BLoC states related to unhovering state
abstract class UnhoveringState extends BlocState {
  const UnhoveringState();
}

/// A base class for all BLoC states related to swinging state
abstract class SwingingState extends BlocState {
  const SwingingState();
}

/// A base class for all BLoC states related to unswinging state
abstract class UnswingingState extends BlocState {
  const UnswingingState();
}

/// A base class for all BLoC states related to spinning state
abstract class SpinningState extends BlocState {
  const SpinningState();
}

/// A base class for all BLoC states related to unspinning state
abstract class UnspinningState extends BlocState {
  const UnspinningState();
}

/// A base class for all BLoC states related to twisting state
abstract class TwistingState extends BlocState {
  const TwistingState();
}

/// A base class for all BLoC states related to untwisting state
abstract class UntwistingState extends BlocState {
  const UntwistingState();
}

/// A base class for all BLoC states related to stretching state
abstract class StretchingState extends BlocState {
  const StretchingState();
}

/// A base class for all BLoC states related to unstretching state
abstract class UnstretchingState extends BlocState {
  const UnstretchingState();
}

/// A base class for all BLoC states related to squeezing state
abstract class SqueezingState extends BlocState {
  const SqueezingState();
}

/// A base class for all BLoC states related to unsqueezing state
abstract class UnsqueezingState extends BlocState {
  const UnsqueezingState();
}

/// A base class for all BLoC states related to expanding state
abstract class ExpandingState extends BlocState {
  const ExpandingState();
}

/// A base class for all BLoC states related to unexpanding state
abstract class UnexpandingState extends BlocState {
  const UnexpandingState();
}

/// A base class for all BLoC states related to collapsing state
abstract class CollapsingState extends BlocState {
  const CollapsingState();
}

/// A base class for all BLoC states related to uncollapsing state
abstract class UncollapsingState extends BlocState {
  const UncollapsingState();
}

/// A base class for all BLoC states related to folding state
abstract class FoldingState extends BlocState {
  const FoldingState();
}

/// A base class for all BLoC states related to unfolding state
abstract class UnfoldingState extends BlocState {
  const UnfoldingState();
}

/// A base class for all BLoC states related to rolling state
abstract class RollingState extends BlocState {
  const RollingState();
}

/// A base class for all BLoC states related to unrolling state
abstract class UnrollingState extends BlocState {
  const UnrollingState();
}

/// A base class for all BLoC states related to scrolling state
abstract class ScrollingState extends BlocState {
  const ScrollingState();
}

/// A base class for all BLoC states related to unscrolling state
abstract class UnscrollingState extends BlocState {
  const UnscrollingState();
}

/// A base class for all BLoC states related to zooming state
abstract class ZoomingState extends BlocState {
  const ZoomingState();
}

/// A base class for all BLoC states related to unzooming state
abstract class UnzoomingState extends BlocState {
  const UnzoomingState();
}

/// A base class for all BLoC states related to panning state
abstract class PanningState extends BlocState {
  const PanningState();
}

/// A base class for all BLoC states related to unpanning state
abstract class UnpanningState extends BlocState {
  const UnpanningState();
}

/// A base class for all BLoC states related to tilting state
abstract class TiltingState extends BlocState {
  const TiltingState();
}

/// A base class for all BLoC states related to untilting state
abstract class UntiltingState extends BlocState {
  const UntiltingState();
}

/// A base class for all BLoC states related to skewing state
abstract class SkewingState extends BlocState {
  const SkewingState();
}

/// A base class for all BLoC states related to unskewing state
abstract class UnskewingState extends BlocState {
  const UnskewingState();
}

/// A base class for all BLoC states related to warping state
abstract class WarpingState extends BlocState {
  const WarpingState();
}

/// A base class for all BLoC states related to unwarping state
abstract class UnwarpingState extends BlocState {
  const UnwarpingState();
}

/// A base class for all BLoC states related to distorting state
abstract class DistortingState extends BlocState {
  const DistortingState();
}

/// A base class for all BLoC states related to undistorting state
abstract class UndistortingState extends BlocState {
  const UndistortingState();
}

/// A base class for all BLoC states related to morphing state
abstract class MorphingState extends BlocState {
  const MorphingState();
}

/// A base class for all BLoC states related to unmorphing state
abstract class UnmorphingState extends BlocState {
  const UnmorphingState();
}

/// A base class for all BLoC states related to transforming state
abstract class TransformingState extends BlocState {
  const TransformingState();
}

/// A base class for all BLoC states related to untransforming state
abstract class UntransformingState extends BlocState {
  const UntransformingState();
}
