import SwiftUI

struct MainView: View {
    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .topGradient) {
                ScrollView {
                    VStack(spacing: 0) {
                        ThemeCard(cornerRadius: 32) {
                            Text("Main")
                                .frame(maxHeight: .infinity)
                        }
                        .frame(height: 150)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("seya")
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("seya")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // todo
                    }) {
                        Image("settings_filled")
                    }
                }
            }
        }
    }
}
