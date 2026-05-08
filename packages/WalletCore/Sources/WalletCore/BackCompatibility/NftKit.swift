import Combine
import Foundation
import HsToolKit
import NftKit
import RxSwift

extension Kit {
    struct DisposedError: Error {}

    public var nftBalancesObservable: Observable<[NftBalance]> {
        nftBalancesPublisher.asObservable()
    }
}
