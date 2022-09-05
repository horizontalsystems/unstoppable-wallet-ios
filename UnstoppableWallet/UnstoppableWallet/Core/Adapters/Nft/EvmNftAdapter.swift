import RxSwift
import NftKit
import MarketKit
import EthereumKit

class EvmNftAdapter {
    private let blockchainType: BlockchainType
    private let evmKitWrapper: EvmKitWrapper
    private let nftKit: NftKit.Kit

    init(blockchainType: BlockchainType, evmKitWrapper: EvmKitWrapper, nftKit: NftKit.Kit) {
        self.blockchainType = blockchainType
        self.evmKitWrapper = evmKitWrapper
        self.nftKit = nftKit
    }

    private func record(nftBalance: NftBalance) -> EvmNftRecord {
        EvmNftRecord(
                blockchainType: blockchainType,
                type: nftBalance.nft.type,
                contractAddress: nftBalance.nft.contractAddress.hex,
                tokenId: nftBalance.nft.tokenId.description,
                tokenName: nftBalance.nft.tokenName,
                balance: nftBalance.balance
        )
    }

}

extension EvmNftAdapter: INftAdapter {

    var userAddress: String {
        evmKitWrapper.evmKit.address.hex
    }

    var nftRecordsObservable: Observable<[NftRecord]> {
        nftKit.nftBalancesObservable
                .map { [weak self] nftBalances in
                    nftBalances.compactMap { self?.record(nftBalance: $0) }
                }
    }

    var nftRecords: [NftRecord] {
        nftKit.nftBalances.map { record(nftBalance: $0) }
    }

    func sync() {
        nftKit.sync()
    }

}

extension EvmNftAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try NftKit.Kit.clear(exceptFor: excludedWalletIds)
    }

}
