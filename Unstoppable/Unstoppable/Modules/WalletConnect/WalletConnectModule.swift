import Foundation

protocol IWalletConnectSignService {
    func approveRequest(id: Int, result: Any)
    func rejectRequest(id: Int)
}
