/* Implementation of the Dart Event Loop in Dart */

import "dart:async";

typedef void EventLoopTask();

class EventLoop {
  static final List<EventLoopTask> _queue = [];
  static final List<EventLoopTask> _microtasks = [];

  static void run(EventLoopTask task) {
    _queue.add(task);

    if (onTaskAdded != null) {
      onTaskAdded(task);
    }
  }

  static Function onTaskAdded;
  static Function onMicrotaskAdded;

  static void runMicrotask(EventLoopTask task) {
    _microtasks.add(task);

    if (onMicrotaskAdded != null) {
      onMicrotaskAdded(task);
    }
  }

  static void loop() {
    while (_microtasks.isNotEmpty || _queue.isNotEmpty) {
      var queue = new List<EventLoopTask>.from(_queue);
      if (queue.isNotEmpty) {
        for (var i = 0; i < queue.length; i++) {
          _queue.removeAt(0);
        }
      }
      var microtasks = new List<EventLoopTask>.from(_microtasks);
      if (microtasks.isNotEmpty) {
        for (var i = 0; i < microtasks.length; i++) {
          _microtasks.removeAt(0);
        }
      }

      while (microtasks.isNotEmpty) {
        var task = microtasks.removeAt(0);
        task();
      }

      while (queue.isNotEmpty) {
        var task = queue.removeAt(0);
        task();
      }
    }
  }

  static void executeMain(main()) {
    Zone.current.fork(specification: new ZoneSpecification(
      scheduleMicrotask: (Zone self, ZoneDelegate parent, Zone zone, f()) {
        EventLoop.runMicrotask(f);
      },
      createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f()) {
        return new EventLoopTimer(f, duration)..schedule();
      },
      createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f(Timer timer)) {
        var timer;
        return timer = new EventLoopTimer(() {
          f(timer);
        }, duration, true)..schedule();
      }
    )).run(() {
      main();
      loop();
    });
  }
}

class EventLoopTimer implements Timer {
  Function func;
  Function _func;
  final Duration duration;
  bool isPeriodic = false;
  bool _active = true;

  EventLoopTimer(this.func, this.duration, [this.isPeriodic = false]) {
    _func = func;
  }

  void schedule() {
    var watch = new Stopwatch();
    watch.start();

    void scheduleChecker() {
      _func = () {
        if (watch.elapsedMicroseconds >= duration.inMicroseconds) {
          func();
          if (isPeriodic && _active) {
            watch = new Stopwatch();
            watch.start();
            scheduleChecker();
          } else {
            watch.stop();
          }
        } else {
          scheduleChecker();
        }
      };

      EventLoop.runMicrotask(_func);
    }

    scheduleChecker();
  }

  @override
  void cancel() {
    EventLoop._queue.remove(_func);
    _active = false;
  }

  @override
  bool get isActive {
    if (!_active) {
      return _active;
    }

    return EventLoop._queue.contains(_func);
  }
}

void main() {
  EventLoop.onTaskAdded = (task) {
    print("Task Added");
  };

  EventLoop.onMicrotaskAdded = (task) {
    print("Microtask Added");
  };

  EventLoop.executeMain(_main);
}

_main() async {
}
