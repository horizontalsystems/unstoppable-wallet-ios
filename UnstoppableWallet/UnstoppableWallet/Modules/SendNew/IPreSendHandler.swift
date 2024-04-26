import Foundation

protocol IPreSendHandler {
    func sendData(amount: Decimal, address: String, memo: String?) -> SendData?
}
