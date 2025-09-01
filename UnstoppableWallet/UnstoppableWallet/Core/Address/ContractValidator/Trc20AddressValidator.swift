import Foundation
import HsCryptoKit
import HsToolKit
import MarketKit
import TronKit

class Trc20AddressValidator {
    private static let tronGridUrl = "https://api.trongrid.io/wallet/triggerconstantcontract"
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func method(coinUid: String) -> ContractAddressValidatorChain.Method? {
        switch coinUid {
        case "tether":
            return .isBlacklisted
        default: return nil
        }
    }

    private func checkBlacklistedStatus(address: TronKit.Address, contract: TronKit.Address) async throws -> Bool {
        var parameters: [String: Any] = [
            "owner_address": address.hex,
            "contract_address": contract.hex,
            "function_selector": "$methodName(address)",
            "parameter": encodeAddressForContract(address.hex),
            "visible": true,
        ]

        do {
            let result = try await networkManager.fetchJson(url: Self.tronGridUrl, parameters: parameters)
            print(result)

            return false
        } catch {
            print("Error: \(error)")
            return false
        }
    }

    private func encodeAddressForContract(_ base58Address: String) -> String {
        // Convert base58 to hex address for ABI encoding
        // TRON addresses when converted to hex start with 41, we need to remove it and pad to 32 bytes
        let hexAddress = Base58.decode(base58Address).hs.hex
        let addressWithout41 = hexAddress.stripping(prefix: "41")
        return "000000000000000000000000\(addressWithout41)"
    }
}

extension Trc20AddressValidator: IContractAddressValidator {
    func canCheck(blockchainType: BlockchainType) -> Bool {
        blockchainType == .tron
    }

    func supports(token: Token) -> Bool {
        token.blockchainType == .tron && method(coinUid: token.coin.uid) != nil
    }

    func isClear(address: Address, coinUid: String, blockchainType _: MarketKit.BlockchainType, contractAddress: String) async throws -> Bool {
        guard let tronAddress = try? TronKit.Address(address: address.raw) else {
            throw ContractAddressValidatorChain.CheckError.invalidAddress
        }

        guard let contractAddress = try? TronKit.Address(address: contractAddress) else {
            throw ContractAddressValidatorChain.CheckError.invalidContractAddress
        }

        guard let method = method(coinUid: coinUid) else {
            throw ContractAddressValidatorChain.CheckError.noMethod
        }

        return try await checkStatus(address: tronAddress, contract: contractAddress, method: method)
    }
}

extension Trc20AddressValidator {
    func checkStatus(address: TronKit.Address, contract: TronKit.Address, method: ContractAddressValidatorChain.Method) async throws -> Bool {
        switch method {
        case .isBlacklisted: return try await checkBlacklistedStatus(address: address, contract: contract)
        default: throw ContractAddressValidatorChain.CheckError.noMethod
        }
    }
}
