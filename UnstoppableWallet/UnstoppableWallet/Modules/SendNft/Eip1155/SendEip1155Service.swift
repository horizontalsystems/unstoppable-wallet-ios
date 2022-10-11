import Foundation
import UIKit
import MarketKit
import RxSwift
import RxRelay
import EvmKit
import BigInt
import Kingfisher

class SendEip1155Service {
    let nftUid: NftUid
    let assetShortMetadata: NftAssetShortMetadata?
    var nftImage: NftImage?
    private let adapter: INftAdapter
    private let addressService: AddressService
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let nftBalance: Int
    private var nftAmount: Int?
    private var addressData: AddressData?

    private let amountCautionRelay = PublishRelay<Error?>()
    private var amountCaution: Error? = nil {
        didSet {
            amountCautionRelay.accept(amountCaution)
        }
    }

    init(nftUid: NftUid, balance: Int, adapter: INftAdapter, addressService: AddressService, nftMetadataManager: NftMetadataManager) {
        self.nftUid = nftUid
        self.nftBalance = balance
        self.adapter = adapter
        self.addressService = addressService

        assetShortMetadata = nftMetadataManager.assetShortMetadata(nftUid: nftUid)
        nftImage = resolveNftImage()

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                addressData = AddressData(evmAddress: try EvmKit.Address(hex: address.raw), domain: address.domain)
            } catch {
                addressData = nil
            }
        default: addressData = nil
        }

        syncState()
    }

    private func syncState() {
        if case .success = addressService.state, let nftAmount = nftAmount, let addressData = addressData {
            guard let transactionData = adapter.transferEip1155TransactionData(contractAddress: nftUid.contractAddress, to: addressData.evmAddress, tokenId: nftUid.tokenId, value: Decimal(nftAmount)) else {
                state = .notReady
                return
            }
            let sendInfo = SendEvmData.SendInfo(domain: addressData.domain, assetShortMetadata: assetShortMetadata)
            let sendData = SendEvmData(transactionData: transactionData, additionalInfo: .send(info: sendInfo), warnings: [])

            state = .ready(sendData: sendData)
        } else {
            state = .notReady
        }
    }

    private func validEvmAmount(amount: Int) throws -> Int? {
        guard amount <= nftBalance else {
            throw AmountError.insufficientBalance
        }

        return amount
    }

    private func resolveNftImage() -> NftImage? {
        guard let imageUrl = assetShortMetadata?.previewImageUrl, let url = URL(string: imageUrl) else {
            return nil
        }

        if url.pathExtension == "svg", let data = try? ImageCache.default.diskStorage.value(forKey: url.absoluteString), let svgString = String(data: data, encoding: .utf8) {
            return .svg(string: svgString)
        } else if let data = try? ImageCache.default.diskStorage.value(forKey: url.absoluteString), let image = UIImage(data: data) {
            return .image(image: image)
        } else {
            return nil
        }
    }

}

extension SendEip1155Service {

    var availableBalance: DataStatus<Int> {
        .completed(nftBalance)
    }

    var availableBalanceObservable: Observable<DataStatus<Int>> {
        Observable.just(availableBalance)
    }

}

extension SendEip1155Service {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var amountCautionObservable: Observable<Error?> {
        amountCautionRelay.asObservable()
    }

}

extension SendEip1155Service: IIntegerAmountInputService {

    var amount: Int {
        if nftBalance == 1 {    // if balance == 1 just put it in amount cell
            return nftBalance
        }

        return nftAmount ?? 0
    }

    var balance: Int? {
        nftBalance
    }

    var amountObservable: Observable<Int> {
        .empty()
    }

    var balanceObservable: Observable<Int?> {
        .empty()
    }

    func onChange(amount: Int) {
        if amount > 0 {
            do {
                nftAmount = try validEvmAmount(amount: amount)
                amountCaution = nil
            } catch {
                nftAmount = nil
                amountCaution = error
            }
        } else {
            nftAmount = nil
            amountCaution = nil
        }

        syncState()
    }

}

extension SendEip1155Service {

    enum State {
        case ready(sendData: SendEvmData)
        case notReady
    }

    enum AmountError: Error {
        case insufficientBalance
    }

    private struct AddressData {
        let evmAddress: EvmKit.Address
        let domain: String?
    }

}
