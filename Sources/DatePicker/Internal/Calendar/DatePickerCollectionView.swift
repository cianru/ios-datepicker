import UIKit

/// `UICollectionView` implementation which is:
/// - reloading the data source when navigating through pages
/// - restoring `contentOffset` for the current page when changing
///   `bounds.size` or `contentSize` (screen rotation, layout change, etc.)
final class DatePickerCollectionView: UICollectionView {
    typealias Layout = UICollectionViewLayout & DatePickerCollectionViewLayout

    private var currentPage = 0
    private var preferredPage = 0

    private var previousSize = CGSize.zero
    private var previousContentSize = CGSize.zero

    private var layout: Layout

    init(layout: Layout) {
        self.layout = layout
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCollectionViewLayout(_ layout: UICollectionViewLayout, animated: Bool) {
        guard layout != collectionViewLayout else { return }
        super.setCollectionViewLayout(layout, animated: animated)

        if let layout = layout as? Layout {
            self.layout = layout
        }

        updateLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    func setCurrentPage(_ page: Int, animated: Bool) {
        scroll(to: page, animated: animated)
        preferredPage = page
    }
}

// MARK: - Internal

private extension DatePickerCollectionView {
    func updateLayout() {
        guard layout.isReadyForLayout else { return }

        if bounds.size != previousSize || contentSize != previousContentSize {
            // Restoring the contentOffset of the current page
            // when changing bounds or contentSize
            scroll(to: preferredPage, animated: false)
            reloadData()
        } else if currentPage != layout.currentPage {
            // Reloading when going to another page
            reloadData()
        }

        currentPage = layout.currentPage
        preferredPage = layout.currentPage

        previousSize = bounds.size
        previousContentSize = contentSize
    }

    func scroll(to page: Int, animated: Bool) {
        let newOffset = layout.contentOffset(for: page)
        setContentOffset(newOffset, animated: animated)
    }
}
