import Foundation
import RxSwift
import RxCocoa
import CurrencyKit
import MarketKit

protocol ICexAmountInputService: IAmountInputService {
    var cexAsset: CexAsset { get }
}

extension ICexAmountInputService {

    var token: Token? {
        nil
    }

    var tokenObservable: Observable<Token?> {
        .empty()
    }

}

class CexAmountInputViewModel: AmountInputViewModel {

    init(service: ICexAmountInputService, fiatService: FiatService, switchService: AmountTypeSwitchService, decimalParser: AmountDecimalParser) {
        super.init(service: service, fiatService: fiatService, switchService: switchService, decimalParser: decimalParser)
        sync(cexAsset: service.cexAsset)
    }

    private func sync(cexAsset: CexAsset) {
        queue.async { [weak self] in
            self?.coinDecimals = CexAsset.decimals
            self?.fiatService.set(coinValueKind: .cexAsset(cexAsset: cexAsset))
            self?.updateMaxEnabled()
        }
    }

}
