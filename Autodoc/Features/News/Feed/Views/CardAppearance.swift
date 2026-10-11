import UIKit

enum CardAppearance {
    static func styleContainer(_ view: UIView) {
        view.backgroundColor = .cardBackground
        view.layer.cornerRadius = Radius.card
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
    }
}
