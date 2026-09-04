import Foundation
import Starscream
import WalletConnectRelay

struct WCNSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        let socket = WebSocket(url: url)
        socket.callbackQueue = DispatchQueue(label: "com.walletconnect.sdk.sockets", attributes: .concurrent)
        return socket
    }
}
