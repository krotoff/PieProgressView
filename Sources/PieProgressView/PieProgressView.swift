import UIKit.UIView

open class PieProgressView: UIView {

    // MARK: - Public types

    public struct Configuration {

        public struct ColorPair {
            var fillColor: UIColor
            var strokeColor: UIColor

            public init(fillColor: UIColor, strokeColor: UIColor) {
                self.fillColor = fillColor
                self.strokeColor = strokeColor
            }
        }

        var lineWidth: CGFloat
        var animationDuration: TimeInterval
        var startAngle: CGFloat
        var endAngle: CGFloat
        var activeColors: ColorPair
        var inactiveColors: ColorPair

        public init(
            lineWidth: CGFloat,
            animationDuration: TimeInterval,
            startAngle: CGFloat,
            endAngle: CGFloat,
            activeColors: ColorPair,
            inactiveColors: ColorPair
        ) {
            self.lineWidth = lineWidth
            self.animationDuration = animationDuration
            self.startAngle = startAngle
            self.endAngle = endAngle
            self.activeColors = activeColors
            self.inactiveColors = inactiveColors
        }
    }

    // MARK: - Private properties

    private var passed: Int = 0
    private var total: Int = 1

    private var configuration: Configuration

    private var radius: CGFloat { bounds.height / 2 }
    private var startPoint: CGPoint { CGPoint(x: radius, y: radius) }

    // MARK: - View lifecycle

    public init(configuration: Configuration) {
        self.configuration = configuration

        super.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        drawIfPossible()
    }

    // MARK: - Public methods

    public func updateConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    public func updateActiveColors(_ activeColors: Configuration.ColorPair) {
        self.configuration.activeColors = activeColors
    }

    public func updateValues(passed: Int, total: Int, animated: Bool) {
        self.total = max(1, total)
        self.passed = max(0, min(self.total, passed))

        if animated {
            CATransaction.flush()
            CATransaction.begin()
            CATransaction.setAnimationDuration(configuration.animationDuration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))

            layoutSubviews()

            CATransaction.commit()
        } else {
            layoutSubviews()
        }
    }

    // MARK: - Private methods

    private func drawIfPossible() {
        guard bounds.height > 0, bounds.width > 0 else { return }

        countSublayers()

        let cgFloatTotal = CGFloat(total)
        let fullCircleAngle = configuration.endAngle - configuration.startAngle

        let innerRadius = countInnerRadius()
        let outterRadius = radius - innerRadius

        let onePiePieceAngle = fullCircleAngle / cgFloatTotal

        for index in 0..<total {
            let cgFloatIndex = CGFloat(index)
            let startAngle = configuration.startAngle + cgFloatIndex * onePiePieceAngle
            let endAngle = startAngle + onePiePieceAngle
            let innerAngle = (endAngle + startAngle) / 2

            updateSublayerIfPossible(
                index: index,
                path: createPath(startAngle: startAngle, endAngle: endAngle, outterRadius: outterRadius),
                innerRadius: innerRadius,
                innerAngle: innerAngle
            )
        }
    }

    private func createPath(startAngle: CGFloat, endAngle: CGFloat, outterRadius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        if total != 1 {
            path.move(to: startPoint)
        }
        path.addArc(withCenter: startPoint, radius: outterRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        if total != 1 {
            path.addLine(to: startPoint)
        }

        return path
    }

    private func countSublayers() {
        while (layer.sublayers?.count ?? 0) > total {
            layer.sublayers?.last?.removeFromSuperlayer()
        }

        while (layer.sublayers?.count ?? 0) < total {
            layer.addSublayer(CAShapeLayer())
        }
    }

    private func countInnerRadius() -> CGFloat {
        (0..<total).reduce(CGFloat()) { partialResult, next in
            switch next {
            case 0: return partialResult
            case 1...3: return partialResult + configuration.lineWidth
            case 4...10: return partialResult + configuration.lineWidth / 2
            default: return partialResult + configuration.lineWidth / 4
            }
        }
    }

    private func updateSublayerIfPossible(
        index: Int,
        path: UIBezierPath,
        innerRadius: CGFloat,
        innerAngle: CGFloat
    ) {
        guard let pieLayer = layer.sublayers?[index] as? CAShapeLayer else { return }

        let isPassed = index < passed
        let fillColor = isPassed ? configuration.activeColors.fillColor : configuration.inactiveColors.fillColor
        let strokeColor = isPassed ? configuration.activeColors.strokeColor : configuration.inactiveColors.strokeColor

        pieLayer.fillColor = fillColor.cgColor
        pieLayer.strokeColor = strokeColor.cgColor
        pieLayer.lineWidth = configuration.lineWidth
        pieLayer.lineCap = .round
        pieLayer.lineJoin = .round

        pieLayer.path = path.cgPath
        pieLayer.frame = layer.bounds
            .applying(.init(translationX: innerRadius * cos(innerAngle), y: innerRadius * sin(innerAngle)))
    }
}
