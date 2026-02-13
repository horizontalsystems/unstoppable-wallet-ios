import SwiftUI

struct SwapOptionsView: View {
    @Binding var isPresented: Bool
    @Environment(\.openURL) var openURL

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSTitleView(showGrabber: true, title: "swap_options.title".localized, isPresented: $isPresented)

                ThemeText("swap_options.description".localized, style: .subhead)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                ListSection {
                    Cell(
                        left: {
                            Image("telegram").cornerRadius(4)
                        },
                        middle: {
                            MultiText(title: "Unstoppable Telegram bot")
                        },
                        right: {
                            ThemeImage("arrow_b_right", size: 20)
                        },
                        action: {
                            let username = "unstoppable_swap_bot"
                            let appURL = URL(string: "tg://resolve?domain=\(username)")!
                            let webURL = URL(string: "https://t.me/\(username)")!

                            if UIApplication.shared.canOpenURL(appURL) {
                                openURL(appURL)
                            } else {
                                openURL(webURL)
                            }
                        }
                    )

                    Cell(
                        left: {
                            Image("unstoppable").cornerRadius(4)
                        },
                        middle: {
                            MultiText(title: "Unstoppable Swap site")
                        },
                        right: {
                            ThemeImage("arrow_b_right", size: 20)
                        },
                        action: {
                            Coordinator.shared.present(url: URL(string: "https://swap.unstoppable.money"))
                        }
                    )
                }
                .themeListStyle(.bordered)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)

                Button(
                    action: {
                        isPresented = false
                    },
                    label: {
                        Text("button.cancel".localized)
                    }
                )
                .buttonStyle(PrimaryButtonStyle(style: .gray))
                .padding(EdgeInsets(top: 24, leading: 24, bottom: 16, trailing: 24))
            }
        }
    }
}
