struct MultiSwapButtonState {
    let title: String
    let style: ThemeButton.Style
    let disabled: Bool
    let showProgress: Bool
    let progress: Double?
    let preSwapStep: MultiSwapPreSwapStep?
    let identifier: String

    init(title: String, style: ThemeButton.Style = .secondary, disabled: Bool = false, showProgress: Bool = false, progress: Double? = nil, preSwapStep: MultiSwapPreSwapStep? = nil, identifier: String = TestTags.swapNext) {
        self.title = title
        self.style = style
        self.disabled = disabled
        self.showProgress = showProgress
        self.progress = progress
        self.preSwapStep = preSwapStep
        self.identifier = identifier
    }
}
