import SwiftUI

struct WelcomeScreenView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    private let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start: Date?
    @State private var step: WelcomeTimeline.Step = .initial
    @State private var isFinishing = false
    @State private var screenOpacity: Double = 1

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        ThemeNavigationStack {
            ZStack {
                WelcomeGlowView(start: start)

                logo

                content
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $viewModel.flow) { flow in
                flowView(flow: flow)
            }
        }
        .opacity(screenOpacity)
        .allowsHitTesting(!isFinishing)
        .task {
            await runTimeline()
        }
        .onChange(of: viewModel.finishRequested) { _, requested in
            if requested {
                finish()
            }
        }
    }

    private var flowBinding: Binding<Bool> {
        Binding(
            get: { !viewModel.finishRequested },
            set: { presented in
                if !presented {
                    viewModel.handleFlowFinished()
                }
            }
        )
    }

    @ViewBuilder private func flowView(flow: WelcomeViewModel.Flow) -> some View {
        switch flow {
        case .createStandard:
            CreateAccountView(walletType: .regular, isPresented: flowBinding)
        case .createPasskey:
            CreateAccountView(walletType: .passkey, isPresented: flowBinding)
        case .passkeyTerms:
            PasskeyTermsView(isPresented: flowBinding)
        case .restoreMnemonic:
            RestoreMnemonicView(isParentPresented: flowBinding)
        case .restorePrivateKey:
            RestorePrivateKeyView(isParentPresented: flowBinding)
        case let .restoreCoins(login):
            RestoreCoinsView(accountName: login.accountName, accountType: login.accountType, isParentPresented: flowBinding)
        case .restoreBackup:
            RestoreBackupListView(isParentPresented: flowBinding, showClose: false)
        case .watch:
            WatchView(isPresented: flowBinding, showClose: false)
        }
    }

    private var logoPhase: LogoPhase {
        switch step {
        case .initial: return .hidden
        case .logoShown: return .shown
        default: return .gone
        }
    }

    private var logo: some View {
        WelcomeLogoView()
            .opacity(logoPhase == .shown ? 1 : 0)
            .animation(logoAnimation(appearDuration: Self.logoFadeDuration), value: logoPhase)
            .scaleEffect(logoScale)
            .offset(y: logoPhase == .gone ? Self.logoGoneOffset : 0)
            .animation(logoAnimation(appearDuration: Self.logoScaleDuration), value: logoPhase)
            .accessibilityHidden(true)
    }

    private var logoScale: CGFloat {
        switch logoPhase {
        case .hidden: return Self.logoHiddenScale
        case .shown: return 1
        case .gone: return Self.logoGoneScale
        }
    }

    private func logoAnimation(appearDuration: Double) -> Animation? {
        guard !reduceMotion else {
            return nil
        }

        if logoPhase == .gone {
            return .timingCurve(0.4, 0, 1, 1, duration: Self.logoLeaveDuration)
        }

        return WelcomeReveal.curve(duration: appearDuration)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: .margin24) {
                VStack(alignment: .leading, spacing: Self.headlineLineSpacing) {
                    headline("intro.unwatched".localized, step: .line1)
                    headline("intro.unrestricted".localized, step: .line2)
                    headline("intro.uncompromised".localized, step: .line3)
                }

                ThemeText("intro.be_unstoppable".localized, style: .title3)
                    .modifier(WelcomeReveal(isRevealed: step >= .tail, animated: !reduceMotion))
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)

            ThemeText("intro.caption".localized, style: .bodyR)
                .opacity(Self.captionOpacity)
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin16)
                .modifier(WelcomeReveal(isRevealed: step >= .tail, animated: !reduceMotion))

            Spacer().frame(height: Self.textToButtonsSpacing)

            buttons
        }
    }

    private func headline(_ text: String, step lineStep: WelcomeTimeline.Step) -> some View {
        ThemeText(text, style: .title2)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .modifier(WelcomeReveal(isRevealed: step >= lineStep, animated: !reduceMotion))
    }

    private var buttons: some View {
        VStack(spacing: 0) {
            VStack(spacing: .margin12) {
                ThemeButton(text: "intro.create_new_wallet".localized) {
                    viewModel.showCreateSheet()
                }
                .accessibilityIdentifier(TestTags.introCreateWallet)
                .modifier(WelcomeReveal(isRevealed: step >= .tail, dy: Self.buttonRevealOffset, blur: 0, animated: !reduceMotion))

                ThemeButton(text: "intro.add_existing_wallet".localized, style: .secondary) {
                    viewModel.showImportSheet()
                }
                .accessibilityIdentifier(TestTags.introAddExistingWallet)
                .modifier(WelcomeReveal(isRevealed: step >= .secondButton, dy: Self.buttonRevealOffset, blur: 0, animated: !reduceMotion))
            }
            .padding(.horizontal, .margin24)
            .padding(.top, .margin24)
            .padding(.bottom, .margin16)

            ThemeText(agreementText(), style: .caption, colorStyle: .primary)
                .tint(.themeLeah)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, .margin32)
                .padding(.vertical, .margin8)
                .accessibilityIdentifier(TestTags.introAgreement)
                .modifier(WelcomeReveal(isRevealed: step >= .legal, dy: 0, blur: 0, animated: !reduceMotion))
        }
        .opacity(step >= .tail ? 1 : 0)
        .animation(reduceMotion ? nil : .easeInOut(duration: Self.buttonsFadeDuration), value: step >= .tail)
        .allowsHitTesting(step >= .tail)
    }

    private func agreementText() -> AttributedString {
        let string = "intro.agreement".localized
        let components = string.components(separatedBy: "%@")

        guard components.count == 3 else {
            return AttributedString(string)
        }

        var result = AttributedString("")

        if !components[0].isEmpty {
            result.append(agreementTextPart(string: components[0]))
        }
        result.append(agreementTextPart(string: "intro.agreement.terms_of_use".localized, url: AppConfig.termsOfUseLink))
        if !components[1].isEmpty {
            result.append(agreementTextPart(string: components[1]))
        }
        result.append(agreementTextPart(string: "intro.agreement.privacy_policy".localized, url: AppConfig.privacyPolicyLink))
        if !components[2].isEmpty {
            result.append(agreementTextPart(string: components[2]))
        }

        return result
    }

    private func agreementTextPart(string: String, url: String? = nil) -> AttributedString {
        var part = AttributedString(string)

        if let url {
            part.link = URL(string: url)
            part.font = TextStyle.captionSB.font
            part.foregroundColor = .themeLeah
            part.underlineStyle = .single
        }

        return part
    }

    private func runTimeline() async {
        guard step < WelcomeTimeline.final else {
            return
        }

        if reduceMotion {
            step = WelcomeTimeline.final
            return
        }

        let begin = start ?? Date()
        start = begin

        let current = step

        for nextStep in WelcomeTimeline.Step.allCases where nextStep > current {
            let wait = nextStep.time - Date().timeIntervalSince(begin)

            if wait > 0 {
                try? await Task.sleep(for: .seconds(wait))
            }

            guard !Task.isCancelled else {
                return
            }

            step = nextStep
        }
    }

    private func finish() {
        guard !isFinishing else { return }
        isFinishing = true

        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        withAnimation(.easeInOut(duration: Self.finishDuration)) {
            screenOpacity = 0
        } completion: {
            onFinish()
        }
    }
}

extension WelcomeScreenView {
    private enum LogoPhase {
        case hidden
        case shown
        case gone
    }

    private static let logoHiddenScale: CGFloat = 0.86
    private static let logoGoneScale: CGFloat = 0.92
    private static let logoGoneOffset: CGFloat = -14
    private static let logoFadeDuration: Double = 0.7
    private static let logoScaleDuration: Double = 0.9
    private static let logoLeaveDuration: Double = 0.45

    private static let headlineLineSpacing: CGFloat = -4
    private static let captionOpacity: Double = 0.5
    private static let textToButtonsSpacing: CGFloat = 20
    private static let buttonRevealOffset: CGFloat = 40
    private static let buttonsFadeDuration: Double = 0.5
    private static let finishDuration: Double = 0.3
}

/// Fade 0.7 s, rise 0.9 s and optional de-blur 0.7 s, all on cubic-bezier(0.22, 1, 0.36, 1).
private struct WelcomeReveal: ViewModifier {
    let isRevealed: Bool
    var dy: CGFloat = 28
    var blur: CGFloat = 8
    let animated: Bool

    static func curve(duration: Double) -> Animation {
        .timingCurve(0.22, 1, 0.36, 1, duration: duration)
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: isRevealed ? 0 : blur)
            .opacity(isRevealed ? 1 : 0)
            .animation(animated ? Self.curve(duration: 0.7) : nil, value: isRevealed)
            .offset(y: isRevealed ? 0 : dy)
            .animation(animated ? Self.curve(duration: 0.9) : nil, value: isRevealed)
    }
}
