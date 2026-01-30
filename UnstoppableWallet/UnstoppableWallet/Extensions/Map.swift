import RxSwift

extension ObservableType {
    func flatMapAsync<T>(_ transform: @escaping (Element) async -> T) -> Observable<T> {
        flatMap { element -> Observable<T> in
            Observable.create { observer in
                Task {
                    let result = await transform(element)
                    observer.onNext(result)
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        }
    }
}

extension PrimitiveSequenceType where Trait == SingleTrait {
    func flatMapAsync<T>(_ transform: @escaping (Element) async -> T) -> Single<T> {
        flatMap { element -> Single<T> in
            Single.create { single in
                Task {
                    let result = await transform(element)
                    single(.success(result))
                }
                return Disposables.create()
            }
        }
    }

    static func async(_ work: @escaping () async -> Element) -> Single<Element> {
        Single.create { single in
            Task {
                let result = await work()
                single(.success(result))
            }
            return Disposables.create()
        }
    }
}

extension Sequence {
    func mapAsync<T>(_ transform: (Element) async -> T) async -> [T] {
        var results = [T]()
        for element in self {
            let result = await transform(element)
            results.append(result)
        }
        return results
    }

    func compactMapAsync<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results = [T]()
        for element in self {
            if let result = await transform(element) {
                results.append(result)
            }
        }
        return results
    }
}
