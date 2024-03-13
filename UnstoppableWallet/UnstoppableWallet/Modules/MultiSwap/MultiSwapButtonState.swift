struct MultiSwapButtonState {
    let title: String
    let style: PrimaryButtonStyle.Style
    let disabled: Bool
    let showProgress: Bool
    let preSwapStep: MultiSwapPreSwapStep?

    init(title: String, style: PrimaryButtonStyle.Style = .gray, disabled: Bool = false, showProgress: Bool = false, preSwapStep: MultiSwapPreSwapStep? = nil) {
        self.title = title
        self.style = style
        self.disabled = disabled
        self.showProgress = showProgress
        self.preSwapStep = preSwapStep
    }
}
