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

        snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.hodlerHeight)
        }

        addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func text(lockTimeInterval: HodlerPlugin.LockTimeInterval?) -> String {
        if let lockTimeInterval = lockTimeInterval {
            switch lockTimeInterval {
            case .hour: return "send.hodler_locktime_hour".localized
            case .month: return "send.hodler_locktime_month".localized
            case .halfYear: return "send.hodler_locktime_half_year".localized
            case .year: return "send.hodler_locktime_year".localized
            }
        } else {
            return "send.hodler_locktime_off".localized
        }
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
