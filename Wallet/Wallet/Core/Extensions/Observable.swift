import Foundation
import RxSwift

extension Observable {

    public func subscribeInBackground(disposeBag: DisposeBag, onNext: ((E) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onCompleted: (() -> Void)? = nil, onDisposed: (() -> Void)? = nil) {
        self.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
                .disposed(by: disposeBag)
    }

    public func subscribeAsync(disposeBag: DisposeBag, onNext: ((E) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onCompleted: (() -> Void)? = nil, onDisposed: (() -> Void)? = nil) {
        self.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
                .disposed(by: disposeBag)
    }

    public func subscribeDisposableAsync(disposeBag: DisposeBag, onNext: ((E) -> Void)? = nil, onError: ((Error) -> Void)? = nil, onCompleted: (() -> Void)? = nil, onDisposed: (() -> Void)? = nil) -> Disposable {
        let disposable = self.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
        disposeBag.insert(disposable)
        return disposable
    }

}
