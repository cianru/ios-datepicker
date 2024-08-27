import UIKit

final class DatePickerHorizontalCollectionViewLayout: UICollectionViewLayout {
    var numberOfPages = 1

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
            width: pageLength * CGFloat(numberOfPages),
            height: collectionView.bounds.height
        )
    }

    override func prepare() {
        super.prepare()

        cachedAttrs.removeAll(keepingCapacity: true)
        cachedContentRect = adjustedContentRect

        enumerateSections { section, sectionOffset in
            let itemSize = itemSize(for: section)
            let numberOfCells = numberOfCells(in: section)

            for index in 0..<numberOfCells {
                let indexPath = indexPath(cell: index, section: section)
                let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)

                let column = CGFloat(index % numberOfColumns)
                let row = CGFloat(index / numberOfColumns)

                let origin = CGPoint(
                    x: column * itemSize.width
                        + cachedContentRect.minX
                        + sectionOffset,
                    y: row * itemSize.height
                        + cachedContentRect.minY
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

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }
}

// MARK: - DatePickerCollectionViewLayout

extension DatePickerHorizontalCollectionViewLayout: DatePickerCollectionViewLayout {
    var minimumCellSize: CGSize { settings.appearance.layout.sizes.minimumCellSize }
    var optimalCellSize: CGSize { settings.appearance.layout.sizes.optimalCellSize }
    var numberOfPreloadedPages: (before: Int, after: Int) { (1, 1) }
    var pageLength: CGFloat { collectionView?.bounds.width ?? 0 }
    var pageOffset: CGFloat { collectionView?.contentOffset.x ?? 0 }
    var optimalNumberOfRows: Int { 5 }

    var isPagingEnabled: Bool { true }
    var alwaysBounceHorizontal: Bool { true }
    var alwaysBounceVertical: Bool { false }

    func pageInsets(for bounds: CGRect) -> UIEdgeInsets { .zero }
    func contentOffset(for page: Int) -> CGPoint { .init(x: pageLength * CGFloat(page), y: 0) }

    func sizeThatFits(_ size: CGSize) -> CGSize {
        let minWidth = minimumCellSize.width * CGFloat(numberOfColumns)
        let maxWidth = optimalCellSize.width * CGFloat(numberOfColumns)
        let width = min(max(size.width, minWidth), maxWidth)

        let minHeight = minimumCellSize.height * CGFloat(numberOfRows)
        let maxHeight = optimalCellSize.height * CGFloat(numberOfRows)
        let height = min(max(size.height, minHeight), maxHeight)

        return .init(width: width, height: height)
    }

    func rowSizeThatFits(_ size: CGSize) -> CGSize {
        return .init(
            width: size.width,
            height: size.height / CGFloat(numberOfRows)
        )
    }
}

// MARK: - Internal

private extension DatePickerHorizontalCollectionViewLayout {
    func itemSize(for section: Int) -> CGSize {
        let numberOfRows = numberOfRows(in: section)
        guard numberOfRows > 0 else { return optimalCellSize }

        let width = cachedContentRect.width / CGFloat(numberOfColumns)
        let height = cachedContentRect.height / CGFloat(numberOfRows)

        return .init(
            width: max(minimumCellSize.width, width),
            height: max(minimumCellSize.height, height)
        )
    }

    func numberOfRows(in section: Int) -> Int {
        let numberOfCells = numberOfCells(in: section)
        guard numberOfCells > 0 else { return optimalNumberOfRows }
        // Rounding up the number of rows to a multiple of the number of columns,
        // because the calendar grid is rectangular
        return (numberOfCells + numberOfColumns - 1) / numberOfColumns
    }
}
