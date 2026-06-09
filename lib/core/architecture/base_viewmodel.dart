/// Base classes for state management (ViewModel/BLoC pattern).
///
/// Provides a foundation for managing UI state in a clean, testable way.
library;

import 'package:flutter/foundation.dart';
import '../exceptions/failure.dart';

/// Base view model for managing UI state.
///
/// ViewModel acts as an intermediary between the UI and business logic (use cases).
/// It:
/// - Holds the current state
/// - Exposes it as a ChangeNotifier for reactive updates
/// - Handles events and updates state accordingly
/// - Provides error handling and recovery
abstract class BaseViewModel extends ChangeNotifier {
  /// Initialize the view model.
  ///
  /// Called when the view model is first created.
  Future<void> initialize() async {}

  /// Clean up resources.
  ///
  /// Called when the view model is disposed.
  @override
  Future<void> dispose() async {
    await cleanup();
    super.dispose();
  }

  /// Override this to perform cleanup operations.
  Future<void> cleanup() async {}

  /// Notify listeners that the state has changed.
  ///
  /// Use this to trigger UI updates when state changes.
  @override
  void notifyListeners() {
    super.notifyListeners();
  }

  /// Set an error state.
  void setError(Failure failure) {
    error = failure;
    notifyListeners();
  }

  /// Clear the current error state.
  void clearError() {
    error = null;
    notifyListeners();
  }

  /// Current error state.
  Failure? error;

  /// Whether the view model is currently loading.
  bool get isLoading => loading;

  /// Set loading state.
  @protected
  void setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  /// Whether in loading state.
  @protected
  bool loading = false;
}

/// Generic view model with a single state type.
///
/// Example:
/// ```dart
/// class UserViewModel extends StateViewModel<User> {
///   UserViewModel(this._userRepository);
///
///   final UserRepository _userRepository;
///
///   Future<void> loadUser(String userId) async {
///     setLoading(true);
///     final result = await _userRepository.getUserById(userId);
///     result.when(
///       success: (user) => state = user,
///       failure: setError,
///     );
///     setLoading(false);
///   }
/// }
/// ```
abstract class StateViewModel<T> extends BaseViewModel {
  /// The current state.
  T? state;

  /// Whether state is initialized.
  bool get hasState => state != null;

  /// Reset state to null.
  void resetState() {
    state = null;
    notifyListeners();
  }

  /// Update state.
  void setState(T newState) {
    state = newState;
    notifyListeners();
  }
}

/// View model with list state management.
///
/// Provides convenience methods for managing lists of items.
abstract class ListViewModel<T> extends BaseViewModel {
  /// The list of items.
  List<T> items = [];

  /// Whether the list is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the list has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Replace the entire list.
  void setItems(List<T> newItems) {
    items = newItems;
    notifyListeners();
  }

  /// Add a single item to the list.
  void addItem(T item) {
    items.add(item);
    notifyListeners();
  }

  /// Add multiple items to the list.
  void addItems(List<T> newItems) {
    items.addAll(newItems);
    notifyListeners();
  }

  /// Remove an item from the list.
  void removeItem(T item) {
    items.remove(item);
    notifyListeners();
  }

  /// Remove an item at a specific index.
  void removeItemAt(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      notifyListeners();
    }
  }

  /// Update an item in the list.
  void updateItem(int index, T newItem) {
    if (index >= 0 && index < items.length) {
      items[index] = newItem;
      notifyListeners();
    }
  }

  /// Clear all items from the list.
  void clearItems() {
    items.clear();
    notifyListeners();
  }
}

/// Two-state view model for success/failure scenarios.
///
/// Example:
/// ```dart
/// class LoginViewModel extends BinaryViewModel<User> {
///   Future<void> login(String email, String password) async {
///     setLoading(true);
///     final result = await useCase.call(LoginParams(email, password));
///     result.when(
///       success: setSuccess,
///       failure: setFailure,
///     );
///     setLoading(false);
///   }
/// }
/// ```
abstract class BinaryViewModel<T> extends BaseViewModel {
  /// The success state.
  T? data;

  /// Whether the operation was successful.
  bool get isSuccess => data != null;

  /// Set success state with data.
  void setSuccess(T successData) {
    data = successData;
    error = null;
    notifyListeners();
  }

  /// Reset to initial state.
  void reset() {
    data = null;
    error = null;
    notifyListeners();
  }
}
