import UIKit

protocol ISendConfirmationMemoView: class {
    var memo: String? { get }
}

protocol ISendConfirmationMemoViewDelegate {
    func validateInputText(text: String) -> Bool
}

protocol ISendConfirmationMemoModule: AnyObject {
    var memo: String? { get }
}
