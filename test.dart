import 'package:rxdart/rxdart.dart';

void main() {
  final List<int> list = new List.generate(1000, (i) => i);

  new Observable<num>.fromIterable(list).bufferTest((i) => i > 1).doOnData(print).listen(null);
}
