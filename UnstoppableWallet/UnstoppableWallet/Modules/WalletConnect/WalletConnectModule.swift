import Foundation

protocol IWalletConnectSignService {
    func approveRequest(id: Int, result: Data)
    func rejectRequest(id: Int)
}
