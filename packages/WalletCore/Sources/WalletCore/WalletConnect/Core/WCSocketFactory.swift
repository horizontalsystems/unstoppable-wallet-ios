import Foundation
import Starscream
import WalletConnectRelay

// Starscream's WebSocket is the concrete transport reown's WebSocketConnecting expects
extension WebSocket: WebSocketConnecting {}

struct WCSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        let socket = WebSocket(url: url)
        socket.callbackQueue = DispatchQueue(label: "com.walletconnect.sdk.sockets", attributes: .concurrent)
        return socket
    }
}
