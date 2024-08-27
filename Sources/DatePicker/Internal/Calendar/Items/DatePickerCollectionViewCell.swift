import UIKit

struct DatePickerCollectionViewCellViewModel: Equatable {
    let day: String?
    let textColor: UIColor?
    let annotation: String?
    let style: DatePickerCollectionViewCellStyle
    let rangeStyle: DatePickerCollectionViewCellRangeStyle?
    let isEnabled: Bool
    let accessibility: DatePickerCollectionViewCellAccessibility?
}

enum DatePickerCollectionViewCellStyle: Equatable {
    case available
    case current
    case selected(start: Bool, end: Bool)
    case range
    case unavailable
}

struct DatePickerCollectionViewCellRangeStyle: Equatable {
    let color: UIColor
    let isHighlighted: Bool
    let isStart: Bool
    let isEnd: Bool
}

struct DatePickerCollectionViewCellAccessibility: Equatable {
    let label: String
    let annotationID: String
}

final class DatePickerCollectionViewCell: UICollectionViewCell {
    private struct Layout {
        let edgeLayerInsets: UIEdgeInsets
        let edgeLayerCornerRadius: CGFloat
        let strikethroughLayerSize: CGSize
    }

    private lazy var layout = Layout(
        edgeLayerInsets: .init(
            value: settings.appearance.layout.units(1)
        ),
        edgeLayerCornerRadius: settings.appearance.layout.units(1),
        strikethroughLayerSize: .init(
            width: settings.appearance.layout.units(5),
            height: settings.appearance.layout.sizes.separatorWidth
        )
    )

    var settings: DatePickerSettings = .default

    var viewModel: DatePickerCollectionViewCellViewModel = .init(
        day: nil,
        textColor: nil,
        annotation: nil,
        style: .available,
        rangeStyle: nil,
        isEnabled: true,
        accessibility: nil
    ) {
        didSet {
            guard viewModel != oldValue else { return }
            updateLabels()
            updateLayers()
            updateColors()
            updateAccessibility()
        }
    }

    private lazy var leftRangeLayer = CALayer()
    private lazy var rightRangeLayer = CALayer()

    private lazy var leftEdgeLayer: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = layout.edgeLayerCornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        return layer
    }()

    private lazy var rightEdgeLayer: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = layout.edgeLayerCornerRadius
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return layer
    }()

    private lazy var bothEdgesLayer: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = layout.edgeLayerCornerRadius
        return layer
    }()

    private lazy var strikethroughLayer = CALayer()

    private lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = settings.appearance.fonts.day
        label.textAlignment = .center
        return label
    }()

    private lazy var annotationLabel: UILabel = {
        let label = UILabel()
        label.font = settings.appearance.fonts.annotation
        label.textAlignment = .center
        return label
    }()

    private var edgeLayerRect: CGRect {
        let height = min(bounds.width, bounds.height)
        let width = bounds.width

        return CGRect(
            x: (bounds.width - width) / 2,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        ).inset(by: layout.edgeLayerInsets)
    }

    private var previousSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.size != previousSize {
            previousSize = bounds.size
            layoutLayers()
        }

        layoutLabels()
        removeLayerAnimations()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColors()
    }
}

// MARK: - Layout

private extension DatePickerCollectionViewCell {
    func setupLayers() {
        contentView.layer.addSublayer(leftRangeLayer)
        contentView.layer.addSublayer(rightRangeLayer)
        contentView.layer.addSublayer(leftEdgeLayer)
        contentView.layer.addSublayer(rightEdgeLayer)
        contentView.layer.addSublayer(bothEdgesLayer)
        contentView.layer.addSublayer(strikethroughLayer)
    }

    func setupLayout() {
        contentView.addSubview(dayLabel)
        contentView.addSubview(annotationLabel)
    }

    func layoutLayers() {
        let edgeLayerRect = edgeLayerRect

        leftRangeLayer.frame = edgeLayerRect
        leftRangeLayer.frame.origin.x = 0
        leftRangeLayer.frame.size.width = bounds.width / 2

        rightRangeLayer.frame = edgeLayerRect
        rightRangeLayer.frame.origin.x = bounds.midX
        rightRangeLayer.frame.size.width = bounds.width / 2

        leftEdgeLayer.frame = edgeLayerRect
        leftEdgeLayer.frame.size.width = edgeLayerRect.width / 2

        rightEdgeLayer.frame = edgeLayerRect
        rightEdgeLayer.frame.origin.x = edgeLayerRect.midX
        rightEdgeLayer.frame.size.width = edgeLayerRect.width / 2

        bothEdgesLayer.frame = edgeLayerRect
    }

    func layoutLabels() {
        if annotationLabel.isHidden {
            dayLabel.frame = bounds
            annotationLabel.frame = .zero
        } else {
            // Center day and annitation labelы vertically,
            // one under another
            let edgeLayerRect = edgeLayerRect
            let labelsHeight = dayLabel.font.height()
                + annotationLabel.font.height()
            let yOffset = (bounds.height - labelsHeight) / 2

            dayLabel.frame = CGRect(
                x: edgeLayerRect.minX,
                y: yOffset,
                width: edgeLayerRect.width,
                height: dayLabel.font.height()
            )

            annotationLabel.frame = CGRect(
                x: edgeLayerRect.minX,
                y: dayLabel.frame.maxY,
                width: edgeLayerRect.width,
                height: annotationLabel.font.height()
            )
        }

        strikethroughLayer.frame.size = layout.strikethroughLayerSize
        strikethroughLayer.position = dayLabel.center
    }
}

// MARK: - Internal

private extension DatePickerCollectionViewCell {
    func removeLayerAnimations() {
        contentView.layer.sublayers?.forEach { $0.removeAllAnimations() }
    }

    func updateLabels() {
        dayLabel.text = viewModel.day

        annotationLabel.text = viewModel.annotation
        annotationLabel.isHidden = viewModel.annotation == nil
    }

    func updateLayers() {
        leftRangeLayer.isHidden = true
        rightRangeLayer.isHidden = true
        leftEdgeLayer.isHidden = true
        rightEdgeLayer.isHidden = true
        bothEdgesLayer.isHidden = true
        strikethroughLayer.isHidden = true

        if let rangeStyle = viewModel.rangeStyle {
            updateEdgesVisibilityIfNeeded(
                leftVisible: rangeStyle.isStart,
                rightVisible: rangeStyle.isEnd
            )
        }

        switch viewModel.style {
        case .selected(let start, let end):
            updateEdgesVisibilityIfNeeded(leftVisible: start, rightVisible: end)
            bothEdgesLayer.isHidden = false
        case .range:
            updateEdgesVisibilityIfNeeded(leftVisible: false, rightVisible: false)
        case .unavailable:
            strikethroughLayer.isHidden = false
        default:
            break
        }
    }

    func updateEdgesVisibilityIfNeeded(leftVisible: Bool, rightVisible: Bool) {
        if !leftVisible { leftRangeLayer.isHidden = false }
        if !rightVisible { rightRangeLayer.isHidden = false }
        leftEdgeLayer.isHidden = !leftRangeLayer.isHidden
        rightEdgeLayer.isHidden = !rightRangeLayer.isHidden
    }
}

// MARK: - Accessibility

private extension DatePickerCollectionViewCell {
    func updateAccessibility() {
        isAccessibilityElement = true

        updateAccessibilityTraits()
        updateAccessibilityIdentifiers()
        updateAccessibilityLabels()
    }

    func updateAccessibilityTraits() {
        switch viewModel.style {
        case .selected:
            accessibilityTraits = [.button, .selected]
        case .unavailable:
            accessibilityTraits = [.button, .notEnabled]
        default:
            accessibilityTraits = .button
        }
    }

    func updateAccessibilityIdentifiers() {
        annotationLabel.accessibilityIdentifier = viewModel.accessibility?.annotationID
    }

    func updateAccessibilityLabels() {
        accessibilityLabel = viewModel.accessibility?.label
    }
}

// MARK: - Appearance

private extension DatePickerCollectionViewCell {
    var isDimmed: Bool { tintAdjustmentMode == .dimmed || !viewModel.isEnabled }

    var selectionColor: UIColor {
        return isDimmed
            ? settings.appearance.colors.control.disabled
            : settings.appearance.colors.control.primary
    }

    var selectionRangeColor: UIColor {
        return isDimmed
            ? settings.appearance.colors.control.disabled
            : settings.appearance.colors.control.secondary
    }

    var rangeColor: UIColor? {
        guard let rangeStyle = viewModel.rangeStyle else { return nil }

        return isDimmed
            ? settings.appearance.colors.control.disabled
            : rangeStyle.color
    }

    var strikethroughColor: UIColor {
        return settings.appearance.colors.text.disabled
    }

    func updateColors() {
        updateLabelColors()
        updateLayerColors()
    }

    func updateLabelColors() {
        let primary = settings.appearance.colors.text.primary
        let secondary = settings.appearance.colors.text.secondary
        let disabled = settings.appearance.colors.text.disabled
        let inverted = settings.appearance.colors.text.inverted
        let accent = settings.appearance.colors.text.accent

        if isDimmed {
            dayLabel.textColor = disabled
            annotationLabel.textColor = disabled
        } else {
            switch viewModel.style {
            case .available:
                dayLabel.textColor = viewModel.textColor ?? primary
                annotationLabel.textColor = secondary
            case .current:
                dayLabel.textColor = accent
                annotationLabel.textColor = secondary
            case .selected:
                dayLabel.textColor = inverted
                annotationLabel.textColor = inverted
            case .range:
                dayLabel.textColor = primary
                annotationLabel.textColor = secondary
            case .unavailable:
                dayLabel.textColor = disabled
                annotationLabel.textColor = disabled
            }
        }
    }

    func updateLayerColors() {
        let allRangeLayersHidden = leftRangeLayer.isHidden
            && rightRangeLayer.isHidden
            && leftEdgeLayer.isHidden
            && rightEdgeLayer.isHidden
            && bothEdgesLayer.isHidden

        if !allRangeLayersHidden {
            if let rangeColor = rangeColor?.cgColor {
                leftRangeLayer.backgroundColor = rangeColor
                rightRangeLayer.backgroundColor = rangeColor
                leftEdgeLayer.backgroundColor = rangeColor
                rightEdgeLayer.backgroundColor = rangeColor
            }

            switch viewModel.style {
            case .selected(let start, let end):
                let selectionRangeColor = selectionRangeColor.cgColor
                if !start { leftRangeLayer.backgroundColor = selectionRangeColor }
                if !end { rightRangeLayer.backgroundColor = selectionRangeColor }
                leftEdgeLayer.backgroundColor = selectionRangeColor
                rightEdgeLayer.backgroundColor = selectionRangeColor
                bothEdgesLayer.backgroundColor = selectionColor.cgColor
            case .range:
                let selectionRangeColor = selectionRangeColor.cgColor
                leftRangeLayer.backgroundColor = selectionRangeColor
                rightRangeLayer.backgroundColor = selectionRangeColor
            default:
                break
            }
        }

        if !strikethroughLayer.isHidden {
            strikethroughLayer.backgroundColor = strikethroughColor.cgColor
        }

        removeLayerAnimations()
    }
}
