import RxSwift

final class OptionalSubject<Element>: ObservableType {
    typealias E = Element

    private var _value: Element?
    private let _subject: ReplaySubject<Element>

    var value: Element? {
        return _value
    }

    init(initialValue: Element? = nil) {
        _subject = ReplaySubject.create(bufferSize: 1)

        if let initialValue = initialValue {
            onNext(initialValue)
        }
    }

    func onNext(_ newValue: Element) {
        _value = newValue
        _subject.onNext(newValue)
    }

    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return _subject.subscribe(observer)
    }

    func asObservable() -> Observable<Element> {
        return _subject.asObservable()
    }

}
