import UIKit

final class DatePickerVerticalCollectionViewLayout: UICollectionViewLayout {
    private enum Constants {
        static let preferredNumberOfPages: CGFloat = 2
    }

    var numberOfPages = 1

    private lazy var headerHeight = settings.appearance.layout.units(12)
    private var cachedContentRect = CGRect.zero
    private var cachedAttrs: [IndexPath: UICollectionViewLayoutAttributes] = [:]

    private let settings: DatePickerSettings

    init(settings: DatePickerSettings) {
        self.settings = settings
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView else { return .zero }

        return .init(
            width: collectionView.bounds.width,
            height: pageLength * CGFloat(numberOfPages)
        )
    }

    override func prepare() {
        super.prepare()

        cachedAttrs.removeAll(keepingCapacity: true)
        cachedContentRect = adjustedContentRect

        let itemSize = itemSize

        enumerateSections { section, sectionOffset in
            let headerIndexPath = IndexPath(item: 0, section: section)
            let headerAttrs = headerAttrs(at: headerIndexPath, sectionOffset: sectionOffset)
            cachedAttrs[headerIndexPath] = headerAttrs

            let numberOfCells = numberOfCells(in: section)

            for index in 0..<numberOfCells {
                let indexPath = indexPath(cell: index, section: section)
                let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)

                let column = CGFloat(index % numberOfColumns)
                let row = CGFloat(index / numberOfColumns)

                let origin = CGPoint(
                    x: column * itemSize.width
                        + cachedContentRect.minX,
                    y: row * itemSize.height
                        + cachedContentRect.minY
                        + sectionOffset
                        + headerAttrs.frame.height
                )

                attrs.frame.origin = origin
                attrs.frame.size = itemSize

                cachedAttrs[indexPath] = attrs
            }
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cachedAttrs.values.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cachedAttrs[indexPath]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                       at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {

        return cachedAttrs[indexPath]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }
}

// MARK: - DatePickerCollectionViewLayout

extension DatePickerVerticalCollectionViewLayout: DatePickerCollectionViewLayout {
    var minimumCellSize: CGSize { settings.appearance.layout.sizes.minimumCellSize }
    var optimalCellSize: CGSize { settings.appearance.layout.sizes.optimalCellSize }

    var numberOfPreloadedPages: (before: Int, after: Int) {
        guard let bounds = collectionView?.bounds else { return (1, 1) }
        let numberOfVisiblePages = Int(ceil(bounds.height / pageLength))
        return (before: 1, after: numberOfVisiblePages)
    }

    var pageLength: CGFloat {
        return itemSize.height * CGFloat(optimalNumberOfRows)
            + headerHeight
    }

    var pageOffset: CGFloat { collectionView?.contentOffset.y ?? 0 }
    var optimalNumberOfRows: Int { 6 }

    var isPagingEnabled: Bool { false }
    var alwaysBounceHorizontal: Bool { false }
    var alwaysBounceVertical: Bool { true }

    func pageInsets(for bounds: CGRect) -> UIEdgeInsets {
        // The insets are such that the width of the content
        // is no more than the maximum allowed width
        let width = min(
            settings.appearance.layout.sizes.maxContentWidth,
            bounds.width - settings.appearance.layout.units(4)
        )

        return .init(horizontal: (bounds.width - width) / 2)
    }

    func contentOffset(for page: Int) -> CGPoint { .init(x: 0, y: pageLength * CGFloat(page)) }

    func sizeThatFits(_ size: CGSize) -> CGSize {
        let minWidth = minimumCellSize.width * CGFloat(numberOfColumns)
        let maxWidth = optimalCellSize.width * CGFloat(numberOfColumns)
        let width = min(max(size.width, minWidth), maxWidth)

        let height = optimalCellSize.height * CGFloat(numberOfRows)
            + headerHeight

        return .init(
            width: width,
            height: height * Constants.preferredNumberOfPages
                - optimalCellSize.height
        )
    }

    func rowSizeThatFits(_ size: CGSize) -> CGSize {
        return .init(width: size.width, height: optimalCellSize.height)
    }
}

// MARK: - Internal

private extension DatePickerVerticalCollectionViewLayout {
    var itemSize: CGSize {
        let width = cachedContentRect.width / CGFloat(numberOfColumns)

        return .init(
            width: max(minimumCellSize.width, width),
            height: optimalCellSize.height
        )
    }

    func headerAttrs(at indexPath: IndexPath,
                     sectionOffset: CGFloat) -> UICollectionViewLayoutAttributes {

        let attrs = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            with: indexPath
        )

        attrs.frame = .init(
            x: cachedContentRect.minX,
            y: sectionOffset
                + cachedContentRect.minY,
            width: cachedContentRect.width,
            height: headerHeight
        )

        return attrs
    }
}
