import Combine
import Foundation
import HsToolKit
import NftKit
import RxSwift

extension Kit {
    struct DisposedError: Error {}

    var nftBalancesObservable: Observable<[NftBalance]> {
        nftBalancesPublisher.asObservable()
    }
}
