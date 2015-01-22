import "dart:collection";

class IntRangeIterator implements Iterator<int> {
  final int lower;
  final int upper;
  final bool inclusive;
  final int step;
  int current;
  
  IntRangeIterator.fromRange(IntRange range) : lower = range.lower, upper = range.upper, inclusive = range.inclusive, step = range.step;
  IntRangeIterator(this.lower, this.upper, {this.inclusive: true, this.step: 1});

  @override
  bool moveNext() {
    int next;
    
    if (current == null) {
      current = lower;
      
      if (inclusive) {
        return true;
      }
    }
    
    next = current + step;
    
    if (step.isNegative) {
      if (next == null || inclusive ? next < upper : next <= upper) {
        return false;
      }
    } else {
      if (next == null || inclusive ? next > upper : next >= upper) {
        return false;
      }
    }
    
    current = next;
    return true;
  }
}

class NumberRangeIterator implements BidirectionalIterator<num> {
  final num lower;
  final num upper;
  final bool inclusive;
  final num step;
  num current;
  
  NumberRangeIterator.fromRange(NumberRange range) : lower = range.lower, upper = range.upper, inclusive = range.inclusive, step = range.step;
  NumberRangeIterator(this.lower, this.upper, {this.inclusive: true, this.step: 1});

  @override
  bool moveNext() {
    num next;
    
    if (current == null) {
      current = lower;
      
      if (inclusive) {
        return true;
      }
    }
    
    next = current + step;
    
    if (step.isNegative) {
      if (next == null || inclusive ? next < upper : next <= upper) {
        return false;
      }
    } else {
      if (next == null || inclusive ? next > upper : next >= upper) {
        return false;
      }
    }
    
    current = next;
    return true;
  }

  @override
  bool movePrevious() {
    num prev;
    
    if (current == null) {
      current = upper;
      
      if (inclusive) {
        return true;
      }
    }
    
    prev = current - step;
    
    if (prev == null || inclusive ? prev < lower : prev <= lower) {
      return false;
    }
    
    current = prev;
    return true;
  }
}

class IntRange extends Range<int> {
  final int lower;
  final int upper;
  final bool inclusive;
  final int step;
  
  IntRange(this.lower, this.upper, {this.inclusive: true, this.step: 1});

  @override
  IntRangeIterator get iterator => new IntRangeIterator.fromRange(this);

  @override
  Range<int> reverse() => new IntRange(upper, lower, inclusive: inclusive, step: step * -1);
}

class NumberRange extends Range<num> {
  final num lower;
  final num upper;
  final bool inclusive;
  final num step;
  
  NumberRange(this.lower, this.upper, {this.inclusive: true, this.step: 1});

  @override
  NumberRangeIterator get iterator => new NumberRangeIterator.fromRange(this);

  @override
  Range<num> reverse() => new NumberRange(upper, lower, inclusive: inclusive, step: step * -1);
}

abstract class Range<T> extends IterableBase<T> {
  T get lower;
  T get upper;
  bool get inclusive;
  Range<T> reverse();
}
