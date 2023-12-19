import Combine
import RxSwift

extension Publisher {
    /// Returns an Observable<Output> representing the underlying
    /// Publisher. Upon subscription, the Publisher's sink pushes
    /// events into the Observable. Upon disposing of the subscription,
    /// the sink is cancelled.
    ///
    /// - returns: Observable<Output>
    func asObservable() -> Observable<Output> {
        Observable<Output>.create { observer in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        observer.onCompleted()
                    case let .failure(error):
                        observer.onError(error)
                    }
                },
                receiveValue: { value in
                    observer.onNext(value)
                }
            )

            return Disposables.create {
                cancellable.cancel()
            }
        }
    }
}
