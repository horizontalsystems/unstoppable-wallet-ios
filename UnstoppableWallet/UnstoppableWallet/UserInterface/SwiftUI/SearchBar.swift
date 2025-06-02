import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").themeIcon(color: .themeGray)
                TextField("", text: $text, prompt: Text(prompt).foregroundColor(.themeGray))
                    .font(.themeBody)
            }
            .padding(.horizontal, .margin8)
            .padding(.vertical, 7)
            .background(Color.themeSteel.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .padding(.horizontal, .margin16)
        .padding(.bottom, .margin12)
    }
}

struct SearchBarWithCancel: View {
    @Binding var text: String
    let prompt: String
    @FocusState.Binding var focused: Bool

    @State private var cancelVisible = false

    var body: some View {
        ZStack {
            HStack(spacing: .margin12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").themeIcon(color: .themeGray)
                    TextField("", text: $text, prompt: Text(prompt)
                        .foregroundColor(.themeGray))
                        .font(.themeBody)
                        .focused($focused)
                }
                .padding(.horizontal, .margin8)
                .padding(.vertical, 7)
                .background(Color.themeSteel.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                if cancelVisible {
                    Button(action: {
                        focused = false
                        text = ""
                    }) {
                        Text("button.cancel".localized)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: cancelVisible)
        }
        .padding(.horizontal, .margin16)
        .padding(.bottom, .margin12)
        .onChange(of: focused) { focused in
            cancelVisible = focused
        }
    }
}
