import 'dart:async';

class OnErrorResumeNextStreamTransformer2<T> extends StreamTransformerBase<T, T> {
  final StreamTransformer<T, T> transformer;

  // From the orginal version parameter was changed from `Stream<T> recoveryStream` to `Stream<T> Function (dynamic error) recoveryStream`
  OnErrorResumeNextStreamTransformer2(Stream<T> Function(dynamic error) recoveryStream)
      : transformer = _buildTransformer(recoveryStream);

  @override
  Stream<T> bind(Stream<T> stream) => transformer.bind(stream);

  // From the orginal version parameter was changed from `Stream<T> recoveryStream` to `Stream<T> Function (dynamic error) recoveryStream`
  static StreamTransformer<T, T> _buildTransformer<T>(Stream<T> Function(dynamic error) recoveryStream) {
    return new StreamTransformer<T, T>((Stream<T> input, bool cancelOnError) {
      StreamSubscription<T> inputSubscription;
      StreamSubscription<T> recoverySubscription;
      StreamController<T> controller;
      bool shouldCloseController = true;

      void safeClose() {
        if (shouldCloseController) {
          controller.close();
        }
      }

      controller = new StreamController<T>(
          sync: true,
          onListen: () {
            inputSubscription = input.listen(controller.add, onError: (dynamic e, dynamic s) {
              shouldCloseController = false;
              // This line now is calling `recoveryStream` as a function with an error, instead of just using Stream object
              recoverySubscription = recoveryStream(e)
                  .listen(controller.add, onError: controller.addError, onDone: controller.close, cancelOnError: cancelOnError);

              inputSubscription.cancel();
            }, onDone: safeClose, cancelOnError: cancelOnError);
          },
          onPause: ([Future<dynamic> resumeSignal]) {
            inputSubscription?.pause(resumeSignal);
            recoverySubscription?.pause(resumeSignal);
          },
          onResume: () {
            inputSubscription?.resume();
            recoverySubscription?.resume();
          },
          onCancel: () {
            return Future.wait<dynamic>(<Future<dynamic>>[inputSubscription?.cancel(), recoverySubscription?.cancel()]
                .where((Future<dynamic> future) => future != null));
          });

      return controller.stream.listen(null);
    });
  }
}
