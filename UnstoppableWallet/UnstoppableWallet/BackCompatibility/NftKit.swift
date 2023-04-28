import Foundation
import Combine
import RxSwift
import HsToolKit
import NftKit

extension Kit {
    struct DisposedError: Error {}

    public var nftBalancesObservable: Observable<[NftBalance]> {
        nftBalancesPublisher.asObservable()
    }

}
