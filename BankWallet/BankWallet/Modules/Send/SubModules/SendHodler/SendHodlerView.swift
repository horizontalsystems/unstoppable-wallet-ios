import UIKit
import SnapKit
import UIExtensions
import Hodler

class SendHodlerView: UIView {
    private let delegate: ISendHodlerViewDelegate
    let selectableValueView = SelectableValueView(title: "send.hodler_locktime".localized)

    init(delegate: ISendHodlerViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        selectableValueView.delegate = self
        selectableValueView.set(value: text(lockTimeInterval: nil))

        addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func text(lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> String {
        lockTimeInterval.map { $0.title } ?? "send.hodler_locktime_off".localized
    }

}

extension SendHodlerView: ISendHodlerView {

    func setLockTimeInterval(lockTimeInterval: HodlerPlugin.LockTimeInterval?) {
        selectableValueView.set(value: text(lockTimeInterval: lockTimeInterval))
    }

}

extension SendHodlerView: ISelectableValueViewDelegate {

    func onSelectorTap() {
        self.delegate.onLockTimeIntervalSelectorTap()
    }

}
