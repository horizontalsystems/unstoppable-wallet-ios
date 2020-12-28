import RxSwift
import UnstoppableDomainsResolution

class AddressResolutionProvider {
    private let resolution: Resolution?

    init() {
        resolution = try? Resolution()
    }

    func isValid(domain: String) -> Bool {
        resolution?.isSupported(domain: domain) ?? false
    }

    func resolveSingle(domain: String, ticker: String) -> Single<String> {
        Single<String>.create { [weak self] observer in
            self?.resolution?.addr(domain: domain, ticker: ticker) { result in
                switch result {
                case .success(let returnValue):
                    observer(.success(returnValue))
                case .failure(let error):
                    observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

}
