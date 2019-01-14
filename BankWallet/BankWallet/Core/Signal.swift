import RxSwift

typealias Signal = PublishSubject<Void>

extension PublishSubject where Element == Void {

    func notify() {
        self.onNext(())
    }

}
