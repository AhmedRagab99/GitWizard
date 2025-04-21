import Foundation

struct GenericError: Error, LocalizedError {
    var errorDescription: String?

    init(errorDescription: String) {
        self.errorDescription = errorDescription
    }
}
