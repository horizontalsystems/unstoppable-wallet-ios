import LanguageKit
import SwiftUI

struct PasscodeView: View {
    let maxDigits: Int

    @Binding var description: String
    @Binding var errorText: String
    @Binding var passcode: String {
        didSet {
            backspaceVisible = !passcode.isEmpty
        }
    }

    @Binding var biometryType: BiometryType?
    @Binding var lockoutState: LockoutState
    @Binding var shakeTrigger: Int
    let randomEnabled: Bool
    var onTapBiometry: (() -> Void)? = nil

    @State var digits: [Int] = (1 ... 9) + [0]
    @State var backspaceVisible: Bool = false
    @State var randomized: Bool = false {
        didSet {
            if randomized {
                digits = (0 ... 9).shuffled()
            } else {
                digits = (1 ... 9) + [0]
            }
        }
    }

    var body: some View {
        VStack {
            VStack {
                switch lockoutState {
                case .unlocked:
                    Text(description)
                        .font(.themeSubhead2)
                        .foregroundColor(.themeGray)
                        .padding(.horizontal, .margin48)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.opacity.animation(.easeOut))
                        .id(description)

                    HStack(spacing: .margin12) {
                        ForEach(0 ..< maxDigits, id: \.self) { index in
                            Circle()
                                .fill(index < passcode.count ? Color.themeJacob : Color.themeSteel20)
                                .frame(width: .margin12, height: .margin12)
                        }
                    }
                    .modifier(Shake(animatableData: CGFloat(shakeTrigger)))
                    .padding(.vertical, .margin16)
                    .animation(.linear(duration: 0.3), value: shakeTrigger)
                    .animation(.easeOut(duration: 0.1), value: passcode)

                    Text(errorText)
                        .font(.themeCaption)
                        .foregroundColor(.themeLucian)
                        .padding(.horizontal, .margin48)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .transition(.opacity.animation(.easeOut))
                        .id(errorText)
                case let .locked(unlockDate):
                    VStack(spacing: .margin16) {
                        Image("lock_48")
                            .foregroundColor(.themeGray)
                        Text("unlock.disabled_until".localized(DateFormatter.cachedFormatter(format: "\(LanguageHourFormatter.hourFormat):mm:ss").string(from: unlockDate)))
                            .foregroundColor(.themeGray)
                            .font(.themeSubhead2)
                            .padding(.horizontal, .margin48)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            VStack(spacing: .margin24) {
                NumPadView(
                    digits: $digits,
                    biometryType: $biometryType,
                    disabled: Binding(get: { lockoutState.isLocked }, set: { _ in }),
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

                if randomEnabled {
                    Button(action: {
                        randomized.toggle()
                    }) {
                        Text("unlock.random".localized)
                    }
                    .buttonStyle(SecondaryButtonStyle(isActive: randomized))
                    .disabled(lockoutState.isLocked)
                }
            }
            .padding(.bottom, .margin32)
        }
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
