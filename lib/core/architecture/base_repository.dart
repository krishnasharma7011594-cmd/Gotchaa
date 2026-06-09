/// Base repository interface for all repositories.
///
/// Repositories are responsible for abstracting data sources (local, remote, etc)
/// and providing a clean interface to the business logic layer.
library;

import '../exceptions/failure.dart';
import '../exceptions/result.dart';

/// Base class for all repositories.
///
/// Repositories follow the Repository pattern and serve as an abstraction layer
/// between data sources and business logic. They handle:
/// - Data source selection (local cache vs remote API)
/// - Data transformation and mapping
/// - Error handling and recovery
/// - Caching strategies
///
/// All repository methods should return [Result] types for functional error handling.
abstract class BaseRepository {
  /// Initialize the repository (e.g., setup database, load cache).
  ///
  /// Called once when the app starts. Use for expensive initialization operations.
  Future<void> initialize() async {}

  /// Clear all cached data.
  ///
  /// Called when clearing app data or logging out.
  Future<void> clearCache() async {}

  /// Close resources and clean up.
  ///
  /// Called when the app is shutting down.
  Future<void> close() async {}
}

/// Base repository with generic type parameter for consistency.
///
/// Provides common functionality for repositories that deal with specific entity types.
abstract class CrudRepository<T, ID> extends BaseRepository {
  /// Fetch a single entity by ID.
  Future<Result<T, Failure>> getById(ID id);

  /// Fetch all entities.
  Future<Result<List<T>, Failure>> getAll();

  /// Create a new entity.
  Future<Result<T, Failure>> create(T entity);

  /// Update an existing entity.
  Future<Result<T, Failure>> update(T entity);

  /// Delete an entity by ID.
  Future<Result<void, Failure>> delete(ID id);

  /// Check if an entity exists.
  Future<Result<bool, Failure>> exists(ID id);
}

/// Base repository with pagination support.
///
/// Extends [BaseRepository] to provide common pagination patterns.
abstract class PaginatedRepository<T> extends BaseRepository {
  /// Fetch a page of entities.
  ///
  /// [page] should be 1-based (first page is 1, not 0).
  /// [pageSize] determines how many items per page.
  Future<Result<Page<T>, Failure>> getPage({
    required int page,
    required int pageSize,
  });

  /// Search for entities with pagination.
  Future<Result<Page<T>, Failure>> search({
    required String query,
    required int page,
    required int pageSize,
  });
}

/// Represents a page of data with pagination metadata.
class Page<T> {
  /// Creates a [Page].
  Page({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalItems,
  });

  /// The items in this page.
  final List<T> items;

  /// Current page number (1-based).
  final int pageNumber;

  /// Number of items per page.
  final int pageSize;

  /// Total number of items across all pages.
  final int totalItems;

  /// Total number of pages.
  int get totalPages => (totalItems / pageSize).ceil();

  /// Whether there is a next page.
  bool get hasNextPage => pageNumber < totalPages;

  /// Whether there is a previous page.
  bool get hasPreviousPage => pageNumber > 1;

  @override
  String toString() =>
      'Page(items: ${items.length}, page: $pageNumber/$totalPages, total: $totalItems)';
}
