import 'package:flutter/material.dart';

/// A repository interface for data access operations
/// This interface defines the contract for all repository implementations
abstract class Repository<T> {
  /// Get all items
  Future<List<T>> getAll();
  
  /// Get item by id
  Future<T?> getById(String id);
  
  /// Create a new item
  Future<String> create(T item);
  
  /// Update an existing item
  Future<bool> update(String id, T item);
  
  /// Delete an item
  Future<bool> delete(String id);
  
  /// Search for items matching criteria
  Future<List<T>> search(Map<String, dynamic> criteria);
  
  /// Count items
  Future<int> count();
  
  /// Check if an item exists
  Future<bool> exists(String id);
}

/// A generic result class for handling operation outcomes
/// This implements the Result pattern for better error handling
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  
  const Result._({this.data, this.error, required this.isSuccess});
  
  /// Create a success result with data
  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  
  /// Create an empty success result
  factory Result.empty() => Result._(data: null, isSuccess: true);
  
  /// Create an error result with message
  factory Result.failure(String error) => Result._(error: error, isSuccess: false);
  
  /// Map the result to a new type
  Result<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return Result.success(mapper(data));
    } else if (isSuccess) {
      return Result.empty();
    } else {
      return Result.failure(error!);
    }
  }
  
  /// Handle both success and failure cases
  R when<R>({
    required R Function(T? data) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess) {
      return success(data);
    } else {
      return failure(error!);
    }
  }
  
  /// Execute a function only on success
  void onSuccess(Function(T? data) action) {
    if (isSuccess) {
      action(data);
    }
  }
  
  /// Execute a function only on failure
  void onFailure(Function(String error) action) {
    if (!isSuccess) {
      action(error!);
    }
  }
}

/// A service locator for dependency injection
/// This implements a simple service locator pattern
class ServiceLocator {
  ServiceLocator._();
  
  static final ServiceLocator _instance = ServiceLocator._();
  
  /// Get the singleton instance
  static ServiceLocator get instance => _instance;
  
  final Map<Type, Object> _dependencies = {};
  final Map<Type, Object Function()> _factories = {};
  
  /// Register a singleton instance
  void registerSingleton<T extends Object>(T instance) {
    _dependencies[T] = instance;
  }
  
  /// Register a factory function
  void registerFactory<T extends Object>(T Function() factory) {
    _factories[T] = factory;
  }
  
  /// Get a registered instance
  T get<T extends Object>() {
    if (_dependencies.containsKey(T)) {
      return _dependencies[T] as T;
    }
    
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }
    
    throw Exception('Dependency of type $T not registered');
  }
  
  /// Check if a type is registered
  bool isRegistered<T extends Object>() {
    return _dependencies.containsKey(T) || _factories.containsKey(T);
  }
  
  /// Remove a registered type
  void unregister<T extends Object>() {
    _dependencies.remove(T);
    _factories.remove(T);
  }
  
  /// Clear all registrations
  void clear() {
    _dependencies.clear();
    _factories.clear();
  }
}

/// A base class for all models
/// This implements common functionality for all model classes
abstract class BaseModel {
  /// Convert model to a map
  Map<String, dynamic> toMap();
  
  /// Create a copy of the model with updated fields
  BaseModel copyWith();
  
  /// Get the unique identifier of the model
  String get id;
  
  /// Check if the model is valid
  bool isValid();
  
  /// Get validation errors
  List<String> getValidationErrors();
}

/// A base class for all view models
/// This implements the ViewModel pattern for separation of concerns
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;
  
  /// Check if the view model is loading
  bool get isLoading => _isLoading;
  
  /// Get the current error message
  String? get errorMessage => _errorMessage;
  
  /// Check if there is an error
  bool get hasError => _errorMessage != null;
  
  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Initialize the view model
  Future<void> init() async {
    // Override in subclasses
  }
  
  /// Refresh data
  Future<void> refresh() async {
    // Override in subclasses
  }
  
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// A base class for all use cases
/// This implements the Use Case pattern for business logic
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Result<Type>> execute(Params params);
}

/// A class for use cases that don't require parameters
class NoParams {
  const NoParams();
}

/// A base class for all data sources
/// This implements the Data Source pattern for data access
abstract class DataSource<T> {
  /// Get all items
  Future<List<T>> getAll();
  
  /// Get item by id
  Future<T?> getById(String id);
  
  /// Create a new item
  Future<String> create(T item);
  
  /// Update an existing item
  Future<bool> update(String id, T item);
  
  /// Delete an item
  Future<bool> delete(String id);
}

/// A base class for all repositories
/// This implements the Repository pattern for data access
abstract class BaseRepository<T> implements Repository<T> {
  final DataSource<T> dataSource;
  
  BaseRepository(this.dataSource);
  
  @override
  Future<List<T>> getAll() {
    return dataSource.getAll();
  }
  
  @override
  Future<T?> getById(String id) {
    return dataSource.getById(id);
  }
  
  @override
  Future<String> create(T item) {
    return dataSource.create(item);
  }
  
  @override
  Future<bool> update(String id, T item) {
    return dataSource.update(id, item);
  }
  
  @override
  Future<bool> delete(String id) {
    return dataSource.delete(id);
  }
}

/// A factory interface for creating objects
/// This implements the Abstract Factory pattern
abstract class AbstractFactory<T> {
  /// Create an object of type T
  T create();
}

/// A builder interface for constructing complex objects
/// This implements the Builder pattern
abstract class Builder<T> {
  /// Reset the builder
  void reset();
  
  /// Build the object
  T build();
}

/// A strategy interface for defining a family of algorithms
/// This implements the Strategy pattern
abstract class Strategy<Input, Output> {
  /// Execute the strategy
  Output execute(Input input);
}

/// An observer interface for implementing the observer pattern
/// This implements the Observer pattern
abstract class Observer<T> {
  /// Update the observer with new data
  void update(T data);
}

/// A subject interface for the observer pattern
/// This implements the Subject part of the Observer pattern
abstract class Subject<T> {
  /// Register an observer
  void register(Observer<T> observer);
  
  /// Unregister an observer
  void unregister(Observer<T> observer);
  
  /// Notify all observers
  void notifyObservers(T data);
}

/// A command interface for encapsulating a request as an object
/// This implements the Command pattern
abstract class Command {
  /// Execute the command
  void execute();
  
  /// Undo the command
  void undo();
}

/// A state interface for the state pattern
/// This implements the State pattern
abstract class State<T> {
  /// Handle a request in the current state
  void handle(T context);
}

/// A mediator interface for defining how objects interact
/// This implements the Mediator pattern
abstract class Mediator {
  /// Send a message from a colleague
  void send(String message, Object colleague);
}

/// A colleague base class for the mediator pattern
/// This implements the Colleague part of the Mediator pattern
abstract class Colleague {
  final Mediator mediator;
  
  Colleague(this.mediator);
  
  /// Send a message through the mediator
  void send(String message) {
    mediator.send(message, this);
  }
  
  /// Receive a message from the mediator
  void receive(String message);
}

/// A visitor interface for operations on elements of an object structure
/// This implements the Visitor pattern
abstract class Visitor<T> {
  /// Visit an element
  void visit(T element);
}

/// An element interface for the visitor pattern
/// This implements the Element part of the Visitor pattern
abstract class Element {
  /// Accept a visitor
  void accept(Visitor visitor);
}

/// A decorator base class for adding responsibilities to objects
/// This implements the Decorator pattern
abstract class Decorator<T> implements T {
  final T decoratedObject;
  
  Decorator(this.decoratedObject);
}

/// A composite base class for treating individual objects and compositions uniformly
/// This implements the Composite pattern
abstract class Composite<T> {
  /// Add a component
  void add(T component);
  
  /// Remove a component
  void remove(T component);
  
  /// Get a component by index
  T getChild(int index);
  
  /// Get all components
  List<T> getChildren();
}

/// An adapter interface for converting one interface to another
/// This implements the Adapter pattern
abstract class Adapter<From, To> {
  /// Adapt from one type to another
  To adapt(From from);
}

/// A proxy interface for controlling access to an object
/// This implements the Proxy pattern
abstract class Proxy<T> {
  /// Get the real subject
  T getSubject();
}

/// A bridge interface for decoupling an abstraction from its implementation
/// This implements the Bridge pattern
abstract class Bridge<T> {
  /// Get the implementation
  T getImplementation();
}

/// A flyweight factory for sharing objects efficiently
/// This implements the Flyweight pattern
abstract class FlyweightFactory<T> {
  /// Get a flyweight
  T getFlyweight(String key);
}

/// A prototype interface for cloning objects
/// This implements the Prototype pattern
abstract class Prototype<T> {
  /// Clone the object
  T clone();
}

/// A singleton base class for ensuring a class has only one instance
/// This implements the Singleton pattern
abstract class Singleton {
  /// Get the singleton instance
  static Singleton? _instance;
  
  /// Protected constructor
  Singleton._();
  
  /// Get the singleton instance
  static Singleton getInstance() {
    throw UnimplementedError('Subclasses must override getInstance()');
  }
}

/// A template method base class for defining a skeleton of an algorithm
/// This implements the Template Method pattern
abstract class TemplateMethod {
  /// Template method that defines the skeleton of an algorithm
  void templateMethod() {
    step1();
    step2();
    if (hook()) {
      step3();
    }
    step4();
  }
  
  /// Step 1 of the algorithm
  void step1();
  
  /// Step 2 of the algorithm
  void step2();
  
  /// Step 3 of the algorithm
  void step3();
  
  /// Step 4 of the algorithm
  void step4();
  
  /// Hook method that subclasses can override
  bool hook() {
    return true;
  }
}

/// A chain of responsibility base class for passing a request along a chain
/// This implements the Chain of Responsibility pattern
abstract class Handler<T> {
  Handler<T>? successor;
  
  /// Set the successor handler
  void setSuccessor(Handler<T> successor) {
    this.successor = successor;
  }
  
  /// Handle a request
  void handleRequest(T request) {
    if (canHandle(request)) {
      process(request);
    } else if (successor != null) {
      successor!.handleRequest(request);
    } else {
      handleDefault(request);
    }
  }
  
  /// Check if this handler can handle the request
  bool canHandle(T request);
  
  /// Process the request
  void process(T request);
  
  /// Handle the request when no handler in the chain can handle it
  void handleDefault(T request);
}

/// A memento interface for capturing and externalizing an object's internal state
/// This implements the Memento pattern
abstract class Memento<T> {
  /// Get the state
  T getState();
}

/// An originator interface for the memento pattern
/// This implements the Originator part of the Memento pattern
abstract class Originator<T> {
  /// Create a memento
  Memento<T> createMemento();
  
  /// Restore from a memento
  void restoreFromMemento(Memento<T> memento);
}

/// A caretaker class for the memento pattern
/// This implements the Caretaker part of the Memento pattern
class Caretaker<T> {
  final List<Memento<T>> _mementos = [];
  
  /// Add a memento
  void addMemento(Memento<T> memento) {
    _mementos.add(memento);
  }
  
  /// Get a memento by index
  Memento<T> getMemento(int index) {
    return _mementos[index];
  }
  
  /// Get all mementos
  List<Memento<T>> getMementos() {
    return List.unmodifiable(_mementos);
  }
  
  /// Clear all mementos
  void clear() {
    _mementos.clear();
  }
}

/// An interpreter interface for interpreting a language
/// This implements the Interpreter pattern
abstract class Interpreter<Context> {
  /// Interpret an expression
  void interpret(Context context);
}

/// An iterator interface for accessing elements of a collection
/// This implements the Iterator pattern
abstract class Iterator<T> {
  /// Check if there is a next element
  bool hasNext();
  
  /// Get the next element
  T next();
  
  /// Reset the iterator
  void reset();
}

/// An aggregate interface for creating iterators
/// This implements the Aggregate part of the Iterator pattern
abstract class Aggregate<T> {
  /// Create an iterator
  Iterator<T> createIterator();
}
