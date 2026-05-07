import Foundation
import TonSwift

public enum TonConnectResponseBuilder {
    static func buildConnectEventSuccesResponse(requestPayloadItems: [TonConnectRequestPayload.Item], contract: Contract, keyPair: KeyPair, manifest: TonConnectManifest) throws -> TonConnect.ConnectEventSuccess {
        let address = try contract.address()

        let replyItems = requestPayloadItems.compactMap { item in
            switch item {
            case .tonAddress:
                return TonConnect.ConnectItemReply.tonAddress(.init(
                    address: address,
                    network: TonConnect.Network.mainnet,
                    publicKey: keyPair.publicKey,
                    walletStateInit: contract.stateInit
                )
                )
            case let .tonProof(payload):
                return TonConnect.ConnectItemReply.tonProof(.success(.init(
                    address: address,
                    domain: manifest.host,
                    payload: payload,
                    privateKey: keyPair.privateKey
                )))
            case .unknown:
                return nil
            }
        }

        return TonConnect.ConnectEventSuccess(payload: .init(items: replyItems, device: .init()))
    }
}
