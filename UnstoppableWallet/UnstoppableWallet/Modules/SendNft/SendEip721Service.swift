import Foundation
import MarketKit
import RxSwift
import RxRelay
import EthereumKit
import BigInt

class SendEip721Service {
    let nftRecord: EvmNftRecord
    private let disposeBag = DisposeBag()
    private let adapter: INftAdapter
    private let addressService: AddressService

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var addressData: AddressData?

    init(nftRecord: EvmNftRecord, adapter: INftAdapter, addressService: AddressService) {
        self.nftRecord = nftRecord
        self.adapter = adapter
        self.addressService = addressService

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                addressData = AddressData(evmAddress: try EthereumKit.Address(hex: address.raw), domain: address.domain)
            } catch {
                addressData = nil
            }
        default: addressData = nil
        }

        syncState()
    }

    private func syncState() {
        if case .success = addressService.state, let addressData = addressData {
            guard let transactionData = adapter.transferEip721TransactionData(contractAddress: nftRecord.contractAddress, to: addressData.evmAddress, tokenId: nftRecord.tokenId) else {
                state = .notReady
                return
            }
            let sendInfo = SendEvmData.SendInfo(domain: addressData.domain)
            let sendData = SendEvmData(transactionData: transactionData, additionalInfo: .send(info: sendInfo), warnings: [])

            state = .ready(sendData: sendData)
        } else {
            state = .notReady
        }
    }

}

extension SendEip721Service {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension SendEip721Service {

    enum State {
        case ready(sendData: SendEvmData)
        case notReady
    }

    private struct AddressData {
        let evmAddress: EthereumKit.Address
        let domain: String?
    }

}
