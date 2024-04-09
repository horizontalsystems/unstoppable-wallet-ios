import Combine
import Foundation
import HsExtensions

class CexDepositService {
    let cexAsset: CexAsset
    let network: CexDepositNetwork?
    private let provider: ICexDepositProvider
    private var tasks = Set<AnyTask>()

    private(set) var state: DataStatus<ReceiveAddress> = .loading {
        didSet {
            stateUpdatedSubject.send(state)
        }
    }

    private let stateUpdatedSubject = PassthroughSubject<DataStatus<ReceiveAddress>, Never>()

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

                let minAmount = network.flatMap { network -> CoinValue? in
                    guard network.minAmount > 0 else {
                        return nil
                    }

                    return CoinValue(
                        kind: .cexAsset(cexAsset: cexAsset),
                        value: network.minAmount
                    )
                }

                let item = DexReceiveAddress(
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

    var coinName: String {
        cexAsset.name
    }

    var coinCode: String {
        cexAsset.coinCode
    }

    var statusUpdatedPublisher: AnyPublisher<DataStatus<ReceiveAddress>, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
}

extension CexDepositService {
    class DexReceiveAddress: ReceiveAddress {
        let address: String
        let memo: String?
        let networkName: String?
        let minAmount: CoinValue?

        init(address: String, coinCode: String, imageUrl: String?, memo: String?, networkName: String?, minAmount: CoinValue?) {
            self.address = address
            self.memo = memo
            self.networkName = networkName
            self.minAmount = minAmount

            super.init(coinCode: coinCode, imageUrl: imageUrl)
        }

        override var raw: String { address }
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
