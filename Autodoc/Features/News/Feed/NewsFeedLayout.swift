import UIKit

enum NewsFeedLayout {
    enum SectionKind {
        case grid
        case footer
    }

    static let minimumCardWidth: CGFloat = 300
    static let interItemSpacing: CGFloat = Spacing.m
    static let sectionInset: CGFloat = Spacing.m

    static func columnCount(forContentWidth width: CGFloat) -> Int {
        let available = width - sectionInset * 2
        let columns = Int((available + interItemSpacing) / (minimumCardWidth + interItemSpacing))
        return max(1, columns)
    }

    static func cardWidth(forContentWidth width: CGFloat) -> CGFloat {
        let columns = CGFloat(columnCount(forContentWidth: width))
        let available = width - sectionInset * 2 - interItemSpacing * (columns - 1)
        return max(1, available / columns)
    }

    static func make(sectionKind: @escaping (Int) -> SectionKind?) -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout(
            sectionProvider: { index, environment in
                section(for: sectionKind(index), environment: environment)
            },
            configuration: makeConfiguration()
        )
    }

    private static func makeConfiguration() -> UICollectionViewCompositionalLayoutConfiguration {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = Spacing.m
        return configuration
    }

    private static func section(
        for kind: SectionKind?,
        environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        switch kind {
        case .grid:
            let columns = columnCount(forContentWidth: environment.container.effectiveContentSize.width)
            return gridSection(columns: columns)
        case .footer, nil:
            return footerSection()
        }
    }

    private static func footerSection() -> NSCollectionLayoutSection {
        let section = fullWidthSection(estimatedHeight: 88)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: sectionInset, bottom: Spacing.m, trailing: sectionInset)
        return section
    }

    private static func fullWidthSection(estimatedHeight: CGFloat) -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(estimatedHeight))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [NSCollectionLayoutItem(layoutSize: size)])
        return NSCollectionLayoutSection(group: group)
    }

    private static func gridSection(columns: Int) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1 / CGFloat(columns)),
            heightDimension: .estimated(300)
        )
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: NSCollectionLayoutItem(layoutSize: itemSize),
            count: columns
        )
        group.interItemSpacing = .fixed(interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = interItemSpacing
        section.contentInsets = NSDirectionalEdgeInsets(top: Spacing.xs, leading: sectionInset, bottom: 0, trailing: sectionInset)
        return section
    }
}
