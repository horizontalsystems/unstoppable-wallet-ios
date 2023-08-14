import Combine
import Foundation
import HsExtensions

class CexDepositService {
    typealias ServiceItem = CexDepositService.Item

    let cexAsset: CexAsset
    let network: CexDepositNetwork?
    private let provider: ICexDepositProvider
    private var tasks = Set<AnyTask>()

    private(set) var state: DataStatus<ServiceItem> = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }
    private let stateUpdatedSubject = PassthroughSubject<DataStatus<ServiceItem>, Never>()

    init(cexAsset: CexAsset, network: CexDepositNetwork?, provider: ICexDepositProvider) {
        self.cexAsset = cexAsset
        self.network = network
        self.provider = provider

        load()
    }

    private func load() {
        state = .loading

        Task { [weak self, provider, cexAsset, network] in
            do {
                let (address, memo) = try await provider.deposit(id: cexAsset.id, network: network?.id)

                let minAmount = network.flatMap {network -> CoinValue? in
                    guard network.minAmount > 0 else {
                        return nil
                    }

                    return CoinValue(
                            kind: .cexAsset(cexAsset: cexAsset),
                            value: network.minAmount
                    )
                }

                let item = ServiceItem(
                        address: address,
                        coinCode: cexAsset.coinCode,
                        imageUrl: cexAsset.coin?.imageUrl,
                        memo: memo,
                        networkName: network?.name,
                        minAmount: minAmount
                )

                self?.state = .completed(item)
            } catch {
                let error = ReceiveAddressModule.ErrorItem(
                        icon: "sync_error_48",
                        text: "cex_deposit.failed".localized
                ) { [weak self] in
                    self?.load()
                }

                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CexDepositService: IReceiveAddressService {

    var title: String {
        "cex_deposit.title".localized(cexAsset.coinCode)
    }

    var coinCode: String {
        cexAsset.coinCode
    }

    var statusUpdatedPublisher: AnyPublisher<DataStatus<ServiceItem>, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }

}

extension CexDepositService {

    struct Item {
        let address: String
        let coinCode: String
        let imageUrl: String?
        let memo: String?
        let networkName: String?
        let minAmount: CoinValue?
    }

    enum CexDepositError: LocalizedError {
        case syncError

        public var errorDescription: String? {
            switch self {
            case .syncError: return "cex_deposit.failed".localized
            }
        }
    }

}
