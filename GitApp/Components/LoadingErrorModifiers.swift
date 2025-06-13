import SwiftUI

// MARK: - Loading Modifier
struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    let errorMessage: String?
    @State private var showAlert: Bool = false

    func body(content: Content) -> some View {
        content
            .onChange(of: errorMessage) { newValue in
                showAlert = newValue != nil
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    showAlert = false
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }

    func errorAlert(_ errorMessage: String?) -> some View {
        modifier(ErrorAlertModifier(errorMessage: errorMessage))
    }
}
