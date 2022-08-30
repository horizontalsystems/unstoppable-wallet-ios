import RxSwift
import NftKit
import MarketKit
import EthereumKit

class EvmNftAdapter {
    private let blockchainType: BlockchainType
    private let nftKit: NftKit.Kit
    private let address: EthereumKit.Address

    init(blockchainType: BlockchainType, nftKit: NftKit.Kit, address: EthereumKit.Address) {
        self.blockchainType = blockchainType
        self.nftKit = nftKit
        self.address = address
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
        address.hex
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
