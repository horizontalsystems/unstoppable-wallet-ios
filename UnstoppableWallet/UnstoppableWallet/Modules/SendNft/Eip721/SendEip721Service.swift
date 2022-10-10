import Foundation
import UIKit
import MarketKit
import RxSwift
import RxRelay
import EvmKit
import BigInt
import Kingfisher

class SendEip721Service {
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

    private var addressData: AddressData?

    init(nftUid: NftUid, adapter: INftAdapter, addressService: AddressService, nftMetadataManager: NftMetadataManager) {
        self.nftUid = nftUid
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
        if case .success = addressService.state, let addressData = addressData {
            guard let transactionData = adapter.transferEip721TransactionData(contractAddress: nftUid.contractAddress, to: addressData.evmAddress, tokenId: nftUid.tokenId) else {
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
        let evmAddress: EvmKit.Address
        let domain: String?
    }

}
