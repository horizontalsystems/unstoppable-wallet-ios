struct MultiSwapButtonState {
    let title: String
    let disabled: Bool
    let showProgress: Bool
    let preSwapStep: MultiSwapPreSwapStep?

    init(title: String, disabled: Bool = false, showProgress: Bool = false, preSwapStep: MultiSwapPreSwapStep? = nil) {
        self.title = title
        self.disabled = disabled
        self.showProgress = showProgress
        self.preSwapStep = preSwapStep
    }
}
