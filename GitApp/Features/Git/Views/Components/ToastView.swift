import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

enum ToastType {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

class ToastManager: ObservableObject {
    @Published var isShowing = false
    @Published var message = ""
    @Published var type: ToastType = .info

    func show(message: String, type: ToastType = .info) {
        self.message = message
        self.type = type
        withAnimation(.spring()) {
            self.isShowing = true
        }

        // Auto hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                self.isShowing = false
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager

    func body(content: Content) -> some View {
        ZStack {
            content

            if toastManager.isShowing {
                VStack {
                    Spacer()
                    ToastView(message: toastManager.message, type: toastManager.type)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

extension View {
    func toast(toastManager: ToastManager) -> some View {
        modifier(ToastModifier(toastManager: toastManager))
    }
}
