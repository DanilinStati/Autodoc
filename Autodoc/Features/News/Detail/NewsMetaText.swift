import UIKit

enum NewsMetaText {
    private static let separator = " · "

    static func make(category: String?, dateText: String?) -> NSAttributedString {
        let result = NSMutableAttributedString()

        if let category {
            result.append(NSAttributedString(string: category, attributes: [.foregroundColor: UIColor.brand]))
        }

        if let dateText {
            let prefix = result.length > 0 ? separator : ""
            result.append(NSAttributedString(
                string: prefix + dateText,
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            ))
        }

        return result
    }
}
