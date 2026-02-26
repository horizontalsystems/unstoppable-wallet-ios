import PhotosUI
import SwiftUI

struct ScanQrViewNew: View {
    @StateObject private var viewModel: ScanQrViewModelNew
    @Binding private var isPresented: Bool

    private let reportAfterDismiss: Bool
    private let options: ScanQrModuleNew.Options

    init(reportAfterDismiss: Bool = false, options: ScanQrModuleNew.Options = [.paste, .picker], isPresented: Binding<Bool>, didFetch: ((String) -> Void)?) {
        self.reportAfterDismiss = reportAfterDismiss
        self.options = options
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: ScanQrViewModelNew(didFetch: didFetch))
    }

    var body: some View {
        ThemeView {
            ZStack(alignment: .topTrailing) {
                QrCameraPreviewNew(session: viewModel.session)
                    .ignoresSafeArea()

                QrScannerOverlayViewNew(sideMargin: .margin24, bottomInset: bottomInset)

                if viewModel.cameraPermissionDenied {
                    permissionDeniedView
                }

                if options.contains(.picker) {
                    PhotosPicker(
                        selection: $viewModel.pickerItem,
                        matching: .images
                    ) {
                        Image("scan").icon(size: .size24, colorStyle: .yellow)
                    }
                    .padding(.trailing, .margin24)
                    .padding(.top, .margin24)
                }

                VStack {
                    Spacer()
                    buttons
                }
                .padding(.horizontal, .margin24)
                .padding(.bottom, .margin24)
            }
        }
        .onAppear {
            viewModel.requestCameraAccess()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onReceive(viewModel.resultPublisher) { string in
            if reportAfterDismiss {
                isPresented = false
                DispatchQueue.main.async {
                    viewModel.didFetch?(string)
                }
            } else {
                viewModel.didFetch?(string)
                isPresented = false
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        VStack(spacing: .margin16) {
            if options.contains(.paste) {
                Button(action: { viewModel.onPaste() }) {
                    Text("button.paste".localized)
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
            }

            Button(action: {
                $isPresented.wrappedValue = false
            }) {
                Text("button.cancel".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .gray))
        }
    }

    @ViewBuilder private var permissionDeniedView: some View {
        VStack(spacing: .margin32) {
            Text("access_camera.message".localized)
                .themeSubhead2(color: .themeGray, alignment: .center)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("access_camera.settings".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .transparent))
        }
        .padding(.horizontal, .margin32)
    }

    private var bottomInset: CGFloat {
        var height: CGFloat = .margin24 + PrimaryButton.height
        if options.contains(.paste) {
            height += .margin16 + PrimaryButton.height
        }
        return height
    }
}
