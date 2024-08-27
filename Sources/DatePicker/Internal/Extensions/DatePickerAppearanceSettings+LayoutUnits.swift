import CoreGraphics

extension DatePickerAppearanceSettings.Layout {
    func units(_ n: Int) -> CGFloat {
        return n != 0
            ? units.unit * CGFloat(n)
            : units.unit * 0.5
    }
}
