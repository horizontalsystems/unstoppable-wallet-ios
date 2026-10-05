import Combine
import Foundation
import RxSwift

// Rx boundary for Combine-only consumers; the hop keeps the sink off the provider's queue
extension WhitelistDappProvider {
    func whitelistDappsPublisher() -> AnyPublisher<[WhitelistDapp], Error> {
        Future<[WhitelistDapp], Error> { [self] promise in
            _ = whitelistDapps().subscribe(onSuccess: { promise(.success($0)) }, onError: { promise(.failure($0)) })
        }
        .receive(on: DispatchQueue.global(qos: .utility))
        .eraseToAnyPublisher()
    }
}
