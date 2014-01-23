library everyday.shared.pool;

import 'dart:async';

abstract class Borrowed<T> {
  T get borrowed;
  giveBack();
}

abstract class Pool<Borrowed> {
    Future start();
    Future<Borrowed> borrow();
    stop();
}
