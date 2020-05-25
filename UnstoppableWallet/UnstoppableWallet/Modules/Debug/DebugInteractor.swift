import RxSwift

class DebugInteractor {
    weak var delegate: IDebugInteractorDelegate?

    private let disposeBag = DisposeBag()

    private let debugBackgroundManager: IDebugLogger?
    private let pasteboardManager: IPasteboardManager

    init(appManager: IAppManager, debugBackgroundManager: IDebugLogger?, pasteboardManager: IPasteboardManager) {
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
