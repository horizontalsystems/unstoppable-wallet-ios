import Combine
import UIKit
import MarketKit

class DepositViewModel {
    private let service: DepositService
    private let depositViewItemHelperFactory: DepositAddressViewHelperFactory

    private var cancellables = Set<AnyCancellable>()

    private let loadingSubject = CurrentValueSubject<Bool, Never>(true)
    private let errorSubject = CurrentValueSubject<String?, Never>(nil)
    private let viewItemSubject = CurrentValueSubject<ViewItem?, Never>(nil)

    init(service: DepositService, depositViewItemHelperFactory: DepositAddressViewHelperFactory) {
        self.service = service
        self.depositViewItemHelperFactory = depositViewItemHelperFactory

        service.$state
                .sink { [weak self] item in
                    self?.sync(status: item)
                }
                .store(in: &cancellables)
        sync(status: service.state)
    }

    private func sync(status: DataStatus<DepositService.Item>) {
        var loading = false
        var errorString: String? = nil
        switch status {
        case .loading:
            loading = true
        case .failed(let error):
            errorString = error.localizedDescription
        case .completed(let item):
            sync(item: item)
        }
        loadingSubject.send(loading)
        errorSubject.send(errorString)
    }

    private func sync(item: DepositService.Item) {
        let viewItemHelper = depositViewItemHelperFactory.viewHelper(depositAddress: item.address, isMainNet: item.isMainNet)

        let plainColor: UIColor = !item.isMainNet ? .themeLucian : .themeGray
        let additionalColor = viewItemHelper.additionalInfo.customColor ?? plainColor

        let addressTitle = service.watchAccount ? "deposit.address".localized : "deposit.your_address".localized
        let mutableString = NSMutableAttributedString(
                string: addressTitle,
                attributes: [
                    .font: UIFont.subhead2,
                    .foregroundColor: plainColor
                ])

        if let text = viewItemHelper.additionalInfo.text {
            mutableString.append(
                    NSAttributedString(string: " (\(text))", attributes: [
                        .font: UIFont.subhead2,
                        .foregroundColor: additionalColor
                    ])
            )
        }

        let viewItem = ViewItem(
            title: mutableString,
            address: item.address.address,
            placeholderImageName: service.token.placeholderImageName,
            watchAccount: service.watchAccount,
            isMainNet: item.isMainNet,
            fields: viewItemHelper.fields,
            additionalInfo: viewItemHelper.additionalInfo
        )

        viewItemSubject.send(viewItem)
    }

}

extension DepositViewModel {

    var title: String {
        service.watchAccount ? "deposit.address".localized : "deposit.receive_coin".localized(service.coin.code)
    }

    var coin: Coin {
        service.coin
    }

    var loadingPublisher: AnyPublisher<Bool, Never> {
        loadingSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<String?, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var viewItemPublisher: AnyPublisher<ViewItem?, Never> {
        viewItemSubject.eraseToAnyPublisher()
    }

}

extension DepositViewModel {

    struct ViewItem {
        let title: NSAttributedString
        let address: String
        let placeholderImageName: String
        let watchAccount: Bool
        let isMainNet: Bool
        let fields: [String]
        let additionalInfo: DepositAddressViewHelper.AdditionalInfo
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

extension DepositService.AdapterError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .noAdapter: return "deposit.no_adapter.error".localized
        }
    }

}
