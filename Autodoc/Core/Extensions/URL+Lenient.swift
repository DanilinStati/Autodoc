import Foundation

nonisolated extension URL {
    init?(lenient string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return nil
        }

        if let url = URL(string: trimmed) {
            self = url
        } else if
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
            let url = URL(string: encoded)
        {
            self = url
        } else {
            return nil
        }
    }
}
