import SwiftUI

enum SheetSize {
    case small
    case medium
    case large
    case custom(width: CGFloat, height: CGFloat)

    var size: CGSize {
        switch self {
        case .small:
            return CGSize(width: 400, height: 300)
        case .medium:
            return CGSize(width: 500, height: 400)
        case .large:
            return CGSize(width: 600, height: 500)
        case .custom(let width, let height):
            return CGSize(width: width, height: height)
        }
    }
}

struct SheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
//    let size: SheetSize
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            VStack(spacing: 0) {
                sheetContent()
            }
//            .frame(
//                width: size.size.width,
//                height: size.size.height
//            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
            )
        }
    }
}

/// A modifier version of SheetPresenter
extension View {
    func presentSheet<Content: View>(
        isPresented: Binding<Bool>,
        size: SheetSize = .medium,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(SheetPresenter(
            isPresented: isPresented,
//            size: size,
            sheetContent: content
        ))
    }

    /// Present a standard merge sheet
    func presentMergeSheet(
        isPresented: Binding<Bool>,
        viewModel: GitViewModel
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            MergeSheet(
                viewModel: viewModel,
                isPresented: isPresented
            )
        }
    }

    /// Present a standard push sheet
    func presentPushSheet(
        isPresented: Binding<Bool>,
        branches: [Branch],
        currentBranch: Branch?,
        onPush: @escaping ([Branch], Bool) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            PushSheet(
                isPresented: isPresented,
                branches: branches,
                currentBranch: currentBranch,
                onPush: onPush
            )
        }
    }

    /// Present a standard pull sheet
    func presentPullSheet(
        isPresented: Binding<Bool>,
        remotes: [String],
        remoteBranches: [String],
        localBranches: [String],
        currentRemote: String,
        currentRemoteBranch: String,
        currentLocalBranch: String,
        onPull: @escaping (String, String, String, PullSheet.PullOptions) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            PullSheet(
                isPresented: isPresented,
                remotes: remotes,
                remoteBranches: remoteBranches,
                localBranches: localBranches,
                currentRemote: currentRemote,
                currentRemoteBranch: currentRemoteBranch,
                currentLocalBranch: currentLocalBranch,
                onPull: onPull
            )
        }
    }

    /// Present a standard fetch sheet
    func presentFetchSheet(
        isPresented: Binding<Bool>,
        remotes: [String],
        currentRemote: String,
        onFetch: @escaping (String, Bool, Bool, Bool) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            FetchSheet(
                isPresented: isPresented,
                remotes: remotes,
                currentRemote: currentRemote,
                onFetch: onFetch
            )
        }
    }

    /// Present a standard create branch sheet
    func presentCreateBranchSheet(
        isPresented: Binding<Bool>,
        currentBranch: String,
        onCreate: @escaping (String, CommitSource, String?, Bool) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            CreateBranchSheet(
                isPresented: isPresented,
                currentBranch: currentBranch,
                onCreate: onCreate
            )
        }
    }

    /// Present a standard create stash sheet
    func presentCreateStashSheet(
        isPresented: Binding<Bool>,
        onStash: @escaping (String, Bool) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            CreateStashSheet(
                isPresented: isPresented,
                onStash: onStash
            )
        }
    }

    /// Present a standard delete branches sheet
    func presentDeleteBranchesSheet(
        isPresented: Binding<Bool>,
        branches: [Branch],
        onDelete: @escaping ([Branch], Bool, Bool, Bool) -> Void
    ) -> some View {
        self.presentSheet(isPresented: isPresented) {
            DeleteBranchesView(
                isPresented: isPresented,
                branches: branches,
                onDelete: onDelete
            )
        }
    }
}
