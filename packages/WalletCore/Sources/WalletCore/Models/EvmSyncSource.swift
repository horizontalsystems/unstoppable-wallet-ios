import EvmKit
import Foundation

public class EvmSyncSource: Identifiable {
    let name: String
    public let rpcSource: RpcSource
    let transactionSource: EvmKit.TransactionSource

    init(name: String, rpcSource: RpcSource, transactionSource: EvmKit.TransactionSource) {
        self.name = name
        self.rpcSource = rpcSource
        self.transactionSource = transactionSource
    }

    public var id: URL {
        rpcSource.url
    }

    var isHttp: Bool {
        switch rpcSource {
        case .http: return true
        default: return false
        }
    }
}

extension EvmSyncSource: Equatable {
    public static func == (lhs: EvmSyncSource, rhs: EvmSyncSource) -> Bool {
        lhs.rpcSource.url == rhs.rpcSource.url
    }
}

extension RpcSource {
    var url: URL {
        switch self {
        case let .http(urls, _): return urls[0]
        case let .webSocket(url, _): return url
        }
    }
}
