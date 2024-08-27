import UIKit

struct DatePickerHeaderReusableViewModel: Equatable {
    let title: String?
    let isEnabled: Bool
}

final class DatePickerHeaderReusableView: UICollectionReusableView {
    var settings: DatePickerSettings = .default

    var viewModel: DatePickerHeaderReusableViewModel = .init(
        title: nil,
        isEnabled: true
    ) {
        didSet {
            guard viewModel != oldValue else { return }
            updateLabel()
            updateColors()
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = settings.appearance.fonts.month
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutLabel()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }
}

// MARK: - Layout

private extension DatePickerHeaderReusableView {
    func setupLayout() {
        addSubview(titleLabel)
    }

    func layoutLabel() {
        let contentInsets = UIEdgeInsets(
            top: settings.appearance.layout.units(4),
            left: settings.appearance.layout.units(3),
            bottom: settings.appearance.layout.units(3),
            right: settings.appearance.layout.units(3)
        )

        titleLabel.frame = bounds.inset(by: contentInsets)
    }
}

// MARK: - Internal

private extension DatePickerHeaderReusableView {
    func updateLabel() {
        titleLabel.text = viewModel.title
    }
}

// MARK: - Appearance

private extension DatePickerHeaderReusableView {
    var isDimmed: Bool { tintAdjustmentMode == .dimmed || !viewModel.isEnabled }

    func updateColors() {
        updateLabelColor()
    }

    func updateLabelColor() {
        titleLabel.textColor = isDimmed
            ? settings.appearance.colors.text.disabled
            : settings.appearance.colors.text.primary
    }
}
