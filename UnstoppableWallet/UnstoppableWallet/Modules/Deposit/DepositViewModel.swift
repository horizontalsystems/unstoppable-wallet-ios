import UIKit
import MarketKit

class DepositViewModel {
    private let service: DepositService
    private let depositViewItemHelper: DepositAddressViewHelper

    init(service: DepositService, depositViewItemHelper: DepositAddressViewHelper) {
        self.service = service
        self.depositViewItemHelper = depositViewItemHelper
    }

}

extension DepositViewModel {

    var coin: Coin {
        service.coin
    }

    var placeholderImageName: String {
        service.token.placeholderImageName
    }

    var address: String {
        service.address
    }

    var watchAccount: Bool {
        service.watchAccount
    }

    var testNet: Bool {
        depositViewItemHelper.testNet
    }

    var additionalInfo: DepositAddressViewHelper.AdditionalInfo {
        depositViewItemHelper.additionalInfo
    }

}

extension DepositAddressViewHelper.AdditionalInfo {

    var customColor: UIColor? {
        switch self {
        case .none, .plain: return nil
        case .warning: return .themeJacob
        }
    }

}