import Foundation

class DepositViewModel: IDepositView {

    let delegate: IDepositViewDelegate

    init(viewDelegate: IDepositViewDelegate) {
        self.delegate = viewDelegate
    }

    func onCopy(index: Int) {
        delegate.onCopy(index: index)
    }

    func onShare(index: Int) {
        delegate.onShare(index: index)
    }

}
