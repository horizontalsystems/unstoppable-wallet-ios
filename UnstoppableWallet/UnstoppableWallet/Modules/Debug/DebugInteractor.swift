import RxSwift

class DebugInteractor {
    weak var delegate: IDebugInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let debugBackgroundManager: DebugLogger?
    private let pasteboardManager: PasteboardManager

    init(appManager: IAppManager, debugBackgroundManager: DebugLogger?, pasteboardManager: PasteboardManager) {
        self.debugBackgroundManager = debugBackgroundManager
        self.pasteboardManager = pasteboardManager

        appManager.willEnterForegroundObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.delegate?.didEnterForeground()
                })
                .disposed(by: disposeBag)
    }

}

extension DebugInteractor: IDebugInteractor {

    var logs: [String] {
        debugBackgroundManager?.logs ?? ["not available!"]
    }

    func clearLogs() {
        debugBackgroundManager?.clearLogs()
    }

}
