import Foundation

enum CommitType: String, CaseIterable {
    case normal = "Normal"
    case merge = "Merge"
    case revert = "Revert"
    case cherryPick = "Cherry-pick"
    case squash = "Squash"
    case rebase = "Rebase"
    case interactiveRebase = "Interactive Rebase"
    case reset = "Reset"
    case fastForward = "Fast-forward"
    case revertToMergeCommit = "Revert to Merge Commit"
    case rebaseMergeCommit = "Rebase Merge Commit"
    case rebaseMergeCommitInteractive = "Rebase Merge Commit Interactive"
    case rebaseMergeCommitSquash = "Rebase Merge Commit Squash"
}
