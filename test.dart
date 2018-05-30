import 'package:rxdart/rxdart.dart';

void main() {
  final List<int> list = new List<int>.generate(1000, (int i) => i);

  new Observable<num>.fromIterable(list).bufferTest((num i) => i > 1).doOnData(print).listen(null);
}
