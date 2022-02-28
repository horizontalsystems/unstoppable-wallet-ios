import RxSwift
import UnstoppableDomainsResolution

class AddressResolutionProvider {
    private let resolution: Resolution?

    init() {
        resolution = try? Resolution()
    }

    func isValid(domain: String) -> Single<Bool> {
        Single<Bool>.create { [weak self] observer in
            self?.resolution?.isSupported(domain: domain) { result in
                switch result {
                case .success(let valid): observer(.success(valid))
                case .failure(let error): observer(.error(error))
                }
            }

            return Disposables.create()
        }
    }

    func resolveSingle(domain: String, ticker: String, chain: String? = nil) -> Single<Result<String, Error>> {
        Single<Result<String, Error>>.create { [weak self] observer in
            let completionBlock: StringResultConsumer = { result in
                switch result {
                case .success(let returnValue):
                    observer(.success(.success(returnValue)))
                case .failure(let error):
                    observer(.success(.failure(error)))
                }
            }
            if let chain = chain {
                self?.resolution?.multiChainAddress(domain: domain, ticker: ticker, chain: chain, completion: completionBlock)
            } else {
                self?.resolution?.addr(domain: domain, ticker: ticker, completion: completionBlock)
            }

            return Disposables.create()
        }
    }

}
