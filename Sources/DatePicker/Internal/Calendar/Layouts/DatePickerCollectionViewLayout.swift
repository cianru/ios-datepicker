import UIKit

protocol DatePickerCollectionViewLayout: AnyObject {
    /// Minimum cell size
    var minimumCellSize: CGSize { get }

    /// Intrinsic size of the cell
    var optimalCellSize: CGSize { get }

    /// Total number of pages used
    /// to calculate the `contentSize`
    var numberOfPages: Int { get set }

    /// Number of preloaded pages
    /// `before` – before the current one
    /// `after` – after the current one
    var numberOfPreloadedPages: (before: Int, after: Int) { get }

    /// Page size in the main dimension (width or height)
    var pageLength: CGFloat { get }

    /// `contentOffset` of the current page in the main dimension (x or y)
    var pageOffset: CGFloat { get }

    /// Optimal number of rows (may differ from the actual one)
    var optimalNumberOfRows: Int { get }

    /// Insets at the edges of the page
    func pageInsets(for bounds: CGRect) -> UIEdgeInsets

    /// `contentOffset` for a specific page
    func contentOffset(for page: Int) -> CGPoint

    /// Layout size that fits in `size`,
    /// including the row with the week days
    func sizeThatFits(_ size: CGSize) -> CGSize

    /// Size of a single row that fits in `size`
    func rowSizeThatFits(_ size: CGSize) -> CGSize

    /// `UICollectionView` settings
    var isPagingEnabled: Bool { get }
    var alwaysBounceHorizontal: Bool { get }
    var alwaysBounceVertical: Bool { get }
}

// MARK: - Default implementation

extension DatePickerCollectionViewLayout {
    /// First page, which occupies most of the visible area
    var currentPage: Int {
        guard pageLength > 0 else { return 0 }
        return Int((pageOffset + pageLength / 2) / pageLength)
    }

    /// Number of columns
    /// By default it is equal to the number of days in a week
    var numberOfColumns: Int { 7 }

    /// Number of rows, including the row with the week days
    var numberOfRows: Int { optimalNumberOfRows + 1 }

    // MARK: - Helpers

    /// Content rectangle with respect to `pageInsets`, and rounded cell widths,
    /// to avoid pixel rounding errors when dividing the width of the component
    /// by the number of columns
    func adjustedContentRect(for bounds: CGRect) -> CGRect {
        let pageInsets = pageInsets(for: bounds)
        let contentWidth = bounds.size.width - pageInsets.horizontal
        let contentHeight = bounds.size.height - pageInsets.vertical
        let itemWidth = contentWidth / CGFloat(numberOfColumns)
        let adjustedItemWidth = floor(itemWidth)
        let adjustedContentWidth = adjustedItemWidth * CGFloat(numberOfColumns)
        let adjustedXOffset = ((contentWidth - adjustedContentWidth) / 2).screenScaleRounded

        return .init(
            x: adjustedXOffset + pageInsets.left,
            y: pageInsets.top,
            width: adjustedContentWidth,
            height: contentHeight
        )
    }

    func numberOfSupplementaryViews(in section: Int) -> Int { 1 }

    func cell(from indexPath: IndexPath) -> Int {
        return indexPath.item - numberOfSupplementaryViews(in: indexPath.section)
    }

    func indexPath(cell: Int, section: Int) -> IndexPath {
        return .init(
            item: cell + numberOfSupplementaryViews(in: section),
            section: section
        )
    }

    func section(for page: Int) -> Int {
        return page - currentPage + numberOfPreloadedPages.before
    }

    func page(for section: Int) -> Int {
        return section + currentPage - numberOfPreloadedPages.before
    }
}

// MARK: - UICollectionViewLayout extension

extension DatePickerCollectionViewLayout where Self: UICollectionViewLayout {
    /// Indicates that the layout is ready, when there is exists a `UICollectionView`,
    /// and its bounds and page size are known
    var isReadyForLayout: Bool {
        guard let bounds = collectionView?.bounds else { return false }
        return bounds.width > 0
            && bounds.height > 0
            && pageLength > 0
    }

    var adjustedContentRect: CGRect {
        guard let bounds = collectionView?.bounds else { return .zero }
        return adjustedContentRect(for: bounds)
    }

    var pageInsets: UIEdgeInsets {
        guard let bounds = collectionView?.bounds else { return .zero }
        return pageInsets(for: bounds)
    }

    func enumerateSections(_ block: (_ section: Int, _ offset: CGFloat) -> Void) {
        guard let numberOfSection = collectionView?.numberOfSections else { return }

        for section in 0..<numberOfSection {
            let page = page(for: section)
            block(section, CGFloat(page) * pageLength)
        }
    }

    func numberOfCells(in section: Int) -> Int {
        let numberOfSupplementaryViews = numberOfSupplementaryViews(in: section)

        guard
            let numberOfItems = collectionView?.numberOfItems(inSection: section),
            numberOfItems > numberOfSupplementaryViews
        else {
            return 0
        }

        return numberOfItems - numberOfSupplementaryViews
    }
}
