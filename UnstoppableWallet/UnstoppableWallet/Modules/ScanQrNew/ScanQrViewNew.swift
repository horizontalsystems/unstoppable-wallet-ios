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
        ThemeNavigationStack {
            ZStack {
                QrCameraPreviewNew(session: viewModel.session)
                    .ignoresSafeArea()

                QrScannerOverlayViewNew(sideMargin: .margin24, bottomInset: bottomInset)

                if viewModel.cameraPermissionDenied {
                    permissionDeniedView
                }

                VStack {
                    Spacer()
                    buttons
                }
                .padding(.horizontal, .margin24)
                .padding(.bottom, .margin24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("balance.scan".localized)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
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
    }

    @ViewBuilder private var buttons: some View {
        if options.contains(.picker) || options.contains(.paste) {
            HStack(spacing: .margin16) {
                if options.contains(.picker) {
                    PhotosPicker(
                        selection: $viewModel.pickerItem,
                        matching: .images
                    ) {
                        HStack(spacing: .margin8) {
                            Image("gallery").renderingMode(.template)
                            Text("button.photos".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
                }

                if options.contains(.paste) {
                    Button(action: { viewModel.onPaste() }) {
                        HStack(spacing: .margin8) {
                            Image("copy").renderingMode(.template)
                            Text("button.paste".localized)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))
                }
            }
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
        guard options.contains(.picker) || options.contains(.paste) else {
            return 0
        }
        return PrimaryButton.height
    }
}
