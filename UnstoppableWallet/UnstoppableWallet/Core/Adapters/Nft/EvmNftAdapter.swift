import RxSwift
import NftKit
import MarketKit
import EthereumKit
import BigInt

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

    func nftRecord(nftUid: NftUid) -> NftRecord? {
        guard case let .evm(blockchainType, contractAddress, tokenId) = nftUid else {
            return nil
        }

        guard let contractAddress = try? EthereumKit.Address(hex: contractAddress), let tokenId = BigUInt(tokenId) else {
            return nil
        }

        guard let nftBalance = nftKit.nftBalance(contractAddress: contractAddress, tokenId: tokenId) else {
            return nil
        }

        return record(nftBalance: nftBalance)
    }

    func transferEip721TransactionData(contractAddress: String, to: EthereumKit.Address, tokenId: String) -> TransactionData? {
        guard let contractAddress = try? EthereumKit.Address(hex: contractAddress) else {
            return nil
        }

        guard let tokenId = BigUInt(tokenId) else {
            return nil
        }

        return nftKit.transferEip721TransactionData(contractAddress: contractAddress, to: to, tokenId: tokenId)
    }

    func transferEip1155TransactionData(contractAddress: String, to: String, tokenId: String, value: Decimal) -> TransactionData? {
        guard let contractAddress = try? EthereumKit.Address(hex: contractAddress) else {
            return nil
        }

        guard let to = try? EthereumKit.Address(hex: to) else {
            return nil
        }

        guard let tokenId = BigUInt(tokenId) else {
            return nil
        }

        guard let value = BigUInt(value.description) else {
            return nil
        }

        return nftKit.transferEip1155TransactionData(contractAddress: contractAddress, to: to, tokenId: tokenId, value: value)
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
