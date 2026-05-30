import SwiftUI
import Combine
import UIKit

struct FaderView: View {
    let index: Int
    @ObservedObject var state: FaderState
    let label: String
    let bankType: String // "A" or "B"
    let onValueChanged: (Double) -> Void
    @StateObject private var valueCommitter = FaderValueCommitter()
    
    // 計算された値（フラッシュ時は100）
    private var displayValue: Double {
        state.isFlashing ? 100.0 : state.value
    }
    
    private var faderNumber: Int {
        bankType == "B" ? index + 37 : index + 1
    }
    
    var body: some View {
        VStack(spacing: 2) {
            // 値表示
            Text(displayValue == 100.0 ? "FF" : String(format: "%.0f", displayValue))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.gray)
                .frame(height: 14)
            
            // スライダー部分
            VerticalFaderSlider(
                value: state.value,
                onValueChanged: { value in
                    valueCommitter.enqueue(value, commit: onValueChanged)
                },
                onEditingEnded: { value in
                    state.value = value
                    valueCommitter.commitImmediately(value, commit: onValueChanged)
                }
            )
            .frame(maxHeight: .infinity)
            
            // 番号
            Text("\(faderNumber)")
                .font(.system(size: 12, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.black.opacity(0.7))
                .frame(height: 14)
            
            // フラッシュインジケーター
            Circle()
                .fill(state.isFlashing ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle().stroke(state.isFlashing ? Color.red.opacity(0.5) : Color.gray.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: state.isFlashing ? .red : .clear, radius: 1)
            
            // フラッシュボタン
            FlashButton(isFlashing: $state.isFlashing)
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
            
            // ラベル（縦書き表現）
            StaticVerticalLabel(label: label)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct VerticalFaderSlider: UIViewRepresentable {
    let value: Double
    let onValueChanged: (Double) -> Void
    let onEditingEnded: (Double) -> Void
    
    func makeUIView(context: Context) -> VerticalFaderSliderUIView {
        let slider = VerticalFaderSliderUIView()
        slider.value = value
        slider.onValueChanged = onValueChanged
        slider.onEditingEnded = onEditingEnded
        return slider
    }
    
    func updateUIView(_ uiView: VerticalFaderSliderUIView, context: Context) {
        uiView.onValueChanged = onValueChanged
        uiView.onEditingEnded = onEditingEnded
        
        if !uiView.isDragging {
            uiView.value = value
        }
    }
}

private final class VerticalFaderSliderUIView: UIControl {
    var value: Double {
        get { storedValue }
        set {
            let clampedValue = min(100.0, max(0.0, newValue))
            guard abs(storedValue - clampedValue) > 0.01 else { return }
            
            storedValue = clampedValue
            updateKnobFrame()
        }
    }
    
    var onValueChanged: ((Double) -> Void)?
    var onEditingEnded: ((Double) -> Void)?
    private(set) var isDragging = false
    
    private var storedValue = 0.0
    private var trackingStartValue = 0.0
    private var trackingStartY: CGFloat = 0
    private let trackLayer = CALayer()
    private let trackBorderLayer = CAShapeLayer()
    private let knobLayer = CALayer()
    private let knobBorderLayer = CAShapeLayer()
    private let knobLineLayer = CALayer()
    
    private let knobHeight: CGFloat = 24
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTrack()
        updateKnobFrame()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let expandedKnobFrame = knobLayer.frame.insetBy(dx: -6, dy: -12)
        guard expandedKnobFrame.contains(location) else { return false }
        
        isDragging = true
        trackingStartValue = value
        trackingStartY = location.y
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isDragging else { return false }
        
        updateValue(from: touch.location(in: self))
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        guard isDragging else { return }
        
        if let touch {
            updateValue(from: touch.location(in: self))
        }
        
        isDragging = false
        onEditingEnded?(value)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        guard isDragging else { return }
        
        isDragging = false
        onEditingEnded?(value)
    }
    
    private func setupLayers() {
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        
        trackLayer.backgroundColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        trackLayer.cornerRadius = 1
        trackLayer.contentsScale = UIScreen.main.scale
        
        trackBorderLayer.fillColor = UIColor.clear.cgColor
        trackBorderLayer.strokeColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        trackBorderLayer.lineWidth = 1
        trackBorderLayer.contentsScale = UIScreen.main.scale
        
        knobLayer.backgroundColor = UIColor.black.cgColor
        knobLayer.cornerRadius = 3
        knobLayer.shadowColor = UIColor.black.cgColor
        knobLayer.shadowOpacity = 0.2
        knobLayer.shadowRadius = 1
        knobLayer.shadowOffset = CGSize(width: 0, height: 1)
        knobLayer.contentsScale = UIScreen.main.scale
        
        knobBorderLayer.fillColor = UIColor.clear.cgColor
        knobBorderLayer.strokeColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        knobBorderLayer.lineWidth = 1
        knobBorderLayer.contentsScale = UIScreen.main.scale
        
        knobLineLayer.backgroundColor = UIColor.white.cgColor
        knobLineLayer.contentsScale = UIScreen.main.scale
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(trackBorderLayer)
        layer.addSublayer(knobLayer)
        knobLayer.addSublayer(knobBorderLayer)
        knobLayer.addSublayer(knobLineLayer)
    }
    
    private func layoutTrack() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let trackWidth: CGFloat = 2
        let trackFrame = CGRect(
            x: (bounds.width - trackWidth) / 2,
            y: 0,
            width: trackWidth,
            height: bounds.height
        )
        
        trackLayer.frame = trackFrame
        trackBorderLayer.frame = bounds
        trackBorderLayer.path = UIBezierPath(roundedRect: trackFrame, cornerRadius: 1).cgPath
        
        CATransaction.commit()
    }
    
    private func updateValue(from location: CGPoint) {
        let usableHeight = max(0, bounds.height - knobHeight)
        guard usableHeight > 0 else { return }
        
        let dragDelta = trackingStartY - location.y
        let valueDelta = Double((dragDelta / usableHeight) * 100.0)
        let nextValue = trackingStartValue + valueDelta
        
        value = nextValue
        onValueChanged?(value)
    }
    
    private func updateKnobFrame() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let usableHeight = max(0, bounds.height - knobHeight)
        let currentOffset = CGFloat(value / 100.0) * usableHeight
        let knobWidth = bounds.width * 0.9
        let knobY = bounds.height - knobHeight - currentOffset
        let knobFrame = CGRect(
            x: (bounds.width - knobWidth) / 2,
            y: knobY,
            width: knobWidth,
            height: knobHeight
        )
        
        knobLayer.frame = knobFrame
        knobLayer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: knobFrame.size), cornerRadius: 3).cgPath
        knobBorderLayer.frame = knobLayer.bounds
        knobBorderLayer.path = UIBezierPath(roundedRect: knobLayer.bounds, cornerRadius: 3).cgPath
        knobLineLayer.frame = CGRect(
            x: 0,
            y: (knobHeight - 2) / 2,
            width: knobFrame.width,
            height: 2
        )
        
        CATransaction.commit()
    }
}

private final class FaderValueCommitter: ObservableObject {
    private var pendingValue: Double?
    private var pendingCommit: ((Double) -> Void)?
    private var workItem: DispatchWorkItem?
    private var scheduleGeneration = 0
    
    func enqueue(_ value: Double, commit: @escaping (Double) -> Void) {
        pendingValue = value
        pendingCommit = commit
        
        guard workItem == nil else { return }
        
        let generation = scheduleGeneration
        let item = DispatchWorkItem { [weak self] in
            self?.flushPendingValue(for: generation)
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(16), execute: item)
    }
    
    func commitImmediately(_ value: Double, commit: (Double) -> Void) {
        scheduleGeneration += 1
        workItem?.cancel()
        workItem = nil
        pendingValue = nil
        pendingCommit = nil
        commit(value)
    }
    
    private func flushPendingValue(for generation: Int) {
        guard generation == scheduleGeneration else { return }
        
        workItem = nil
        
        guard let value = pendingValue, let commit = pendingCommit else {
            pendingValue = nil
            pendingCommit = nil
            return
        }
        
        pendingValue = nil
        pendingCommit = nil
        commit(value)
    }
}

// フラッシュボタン
struct FlashButton: View {
    @Binding var isFlashing: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isFlashing ? Color.red : Color(white: 0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isFlashing ? Color.red.opacity(0.8) : Color.gray, lineWidth: 1)
            )
            .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 50, perform: {}, onPressingChanged: { pressing in
                isFlashing = pressing
            })
    }
}

// 静的な縦書きラベル（再描画を防ぐため分離）
struct StaticVerticalLabel: View {
    let label: String
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(label.enumerated()), id: \.offset) { _, char in
                if char == "ー" {
                    Text(String(char))
                        .font(.system(size: 11, weight: .medium))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.black.opacity(0.8))
                        .rotationEffect(.degrees(90))
                } else {
                    Text(String(char))
                        .font(.system(size: 11, weight: .medium))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.black.opacity(0.8))
                }
            }
        }
        .frame(height: 75, alignment: .top)
    }
}
