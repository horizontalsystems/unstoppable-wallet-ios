import SwiftUI

struct PasscodeView: View {
    let maxDigits: Int

    let title: String
    let description: String
    @Binding var errorText: String
    let errorIdentifier: String
    @Binding var passcode: String
    @Binding var biometryType: BiometryType?
    @Binding var lockoutState: LockoutState
    @Binding var shakeTrigger: Int
    let randomEnabled: Bool
    let headerTopInset: CGFloat
    var onTapBiometry: (() -> Void)?

    @State private var digits: [Int] = (1 ... 9) + [0]
    @State private var randomized: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, headerTopInset)

            // fills the space between the dots and the numpad; a message too long for it is truncated instead of pushing the numpad
            ZStack(alignment: .top) {
                message
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, .margin64)
            .padding(.vertical, .margin8)

            NumPadView(
                digits: $digits,
                biometryType: $biometryType,
                disabled: lockoutState.isLocked,
                backspaceDisabled: passcode.isEmpty,
                onTapDigit: { digit in
                    guard passcode.count < maxDigits else {
                        return
                    }

                    passcode = passcode + "\(digit)"
                },
                onTapBackspace: {
                    passcode = String(passcode.dropLast())
                },
                onTapBiometry: onTapBiometry
            )

            ZStack {
                if randomEnabled {
                    ThemeButton(text: "unlock.random".localized, style: .secondary, mode: randomized ? .solid : .transparent, size: .small) {
                        setRandomized(!randomized)
                    }
                    .disabled(lockoutState.isLocked)
                    .accessibilityIdentifier(TestTags.pinRandom)
                }
            }
            .frame(height: .buttonSize32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin48)
        }
        .background {
            WelcomeGlowView(start: nil)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Image.lock(size: .iconSize48)
                .padding(.margin24)

            // the ZStack lets the outgoing and incoming text overlap while they cross-fade
            ZStack {
                ThemeText(title, style: .title3)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.animation(.easeOut))
                    .id(title)
                    .accessibilityIdentifier(TestTags.pinTitle)
            }

            HStack(spacing: .margin12) {
                ForEach(0 ..< maxDigits, id: \.self) { index in
                    Circle()
                        .fill(index < passcode.count ? Color.themeBrand : Color.themeBlade)
                        .frame(width: .margin16, height: .margin16)
                }
            }
            .modifier(Shake(animatableData: CGFloat(shakeTrigger)))
            .padding(.margin16)
            .animation(.linear(duration: 0.3), value: shakeTrigger)
            .animation(.easeOut(duration: 0.1), value: passcode)
            .padding(.top, .margin24)
        }
        .padding(.horizontal, .margin64)
    }

    @ViewBuilder private var message: some View {
        if !errorText.isEmpty {
            ThemeText(errorText, style: .subhead, colorStyle: .red)
                .transition(.opacity.animation(.easeOut))
                .id(errorText)
                .accessibilityIdentifier(errorIdentifier)
        } else if !description.isEmpty {
            ThemeText(description, style: .subhead)
                .transition(.opacity.animation(.easeOut))
                .id(description)
                .accessibilityIdentifier(TestTags.pinDescription)
        }
    }

    private func setRandomized(_ value: Bool) {
        randomized = value
        digits = value ? (0 ... 9).shuffled() : (1 ... 9) + [0]
    }

    private struct Shake: GeometryEffect {
        var amount: CGFloat = 8
        var shakesPerUnit = 4
        var animatableData: CGFloat

        func effectValue(size _: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
        }
    }
}
