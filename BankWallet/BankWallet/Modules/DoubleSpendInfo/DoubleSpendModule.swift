import Foundation

protocol IDoubleSpendInfoView: class {
    func showCopied()
}

protocol IDoubleSpendInfoViewDelegate {
    var txHash: String { get }
    var conflictingTxHash: String? { get }

    func onTapHash()
    func onConflictingTapHash()
}

protocol IDoubleSpendInfoInteractor {
    func copy(value: String)
}
