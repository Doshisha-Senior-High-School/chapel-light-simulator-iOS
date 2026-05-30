import Foundation
import SwiftUI
import Combine

class FaderState: ObservableObject, Identifiable {
    let id = UUID()
    @Published var value: Double = 0.0
    @Published var isFlashing: Bool = false
}

class CrossFaderState: ObservableObject {
    @Published var value: Double = 0.0
}

class LightingController: ObservableObject {
    let aFaders: [FaderState] = (0..<36).map { _ in FaderState() }
    let bFaders: [FaderState] = (0..<36).map { _ in FaderState() }
    let crossFader = CrossFaderState()
    
    let lightDefinitions: [String] = [
        "FS下手", "FS上手", "GS下手", "GS上手", "エリアA", "エリアB", "エリアC", "エリアD", "エリアE", "エリアF", "エリアG", "エリアH",
        "アンバー", "青緑", "黄", "青紫", "→アッパー", "青", "緑", "赤", "→ロアー", "青", "緑", "赤",
        "サス下手", "サス中央", "サス上手", "", "SS下手", "SS上手", "", "キャット間接", "1階側面スポ", "2階スポット", "1階座席天井", "ステージ天井"
    ]
    
    let updateTrigger = PassthroughSubject<Void, Never>()
    private let valueQueue = DispatchQueue(label: "jp.co.hunny.Chapel-Light.fader-values", qos: .userInteractive)
    private var aValues = Array(repeating: 0.0, count: 36)
    private var bValues = Array(repeating: 0.0, count: 36)
    private var aFlashing = Array(repeating: false, count: 36)
    private var bFlashing = Array(repeating: false, count: 36)
    private var crossFaderValue = 0.0
    private var updateScheduled = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        for (index, fader) in aFaders.enumerated() {
            fader.$isFlashing
                .sink { [weak self] isFlashing in
                    self?.setFaderFlashing(isFlashing, bankType: "A", index: index)
                }
                .store(in: &cancellables)
        }
        
        for (index, fader) in bFaders.enumerated() {
            fader.$isFlashing
                .sink { [weak self] isFlashing in
                    self?.setFaderFlashing(isFlashing, bankType: "B", index: index)
                }
                .store(in: &cancellables)
        }
        
        crossFader.$value
            .sink { [weak self] value in
                self?.setCrossFaderValue(value)
            }
            .store(in: &cancellables)
    }
    
    func setFaderValue(_ value: Double, bankType: String, index: Int) {
        guard (0..<36).contains(index) else { return }
        
        valueQueue.async { [weak self] in
            guard let self else { return }
            
            if bankType == "A" {
                guard abs(self.aValues[index] - value) > 0.05 else { return }
                self.aValues[index] = value
            } else {
                guard abs(self.bValues[index] - value) > 0.05 else { return }
                self.bValues[index] = value
            }
            
            self.scheduleUpdate()
        }
    }
    
    func resetAllFaders() {
        for fader in aFaders + bFaders {
            fader.value = 0.0
            fader.isFlashing = false
        }
        crossFader.value = 0.0
        
        valueQueue.async { [weak self] in
            guard let self else { return }
            
            self.aValues = Array(repeating: 0.0, count: 36)
            self.bValues = Array(repeating: 0.0, count: 36)
            self.aFlashing = Array(repeating: false, count: 36)
            self.bFlashing = Array(repeating: false, count: 36)
            self.crossFaderValue = 0.0
            self.scheduleUpdate()
        }
    }
    
    func makeCombinedFaderValuesJSON(completion: @escaping (String) -> Void) {
        valueQueue.async { [weak self] in
            guard let self else { return }
            
            let values = self.combinedFaderValues()
            
            guard let json = try? JSONSerialization.data(withJSONObject: values, options: []),
                  let jsonString = String(data: json, encoding: .utf8) else {
                return
            }
            
            DispatchQueue.main.async {
                completion(jsonString)
            }
        }
    }
    
    // クロスフェーダーとフラッシュを考慮した最終的な値(0.0〜100.0)を計算
    func getCombinedFaderValues() -> [Double] {
        valueQueue.sync {
            combinedFaderValues()
        }
    }
    
    private func setFaderFlashing(_ isFlashing: Bool, bankType: String, index: Int) {
        guard (0..<36).contains(index) else { return }
        
        valueQueue.async { [weak self] in
            guard let self else { return }
            
            if bankType == "A" {
                self.aFlashing[index] = isFlashing
            } else {
                self.bFlashing[index] = isFlashing
            }
            
            self.scheduleUpdate()
        }
    }
    
    private func setCrossFaderValue(_ value: Double) {
        valueQueue.async { [weak self] in
            guard let self else { return }
            guard abs(self.crossFaderValue - value) > 0.05 else { return }
            
            self.crossFaderValue = value
            self.scheduleUpdate()
        }
    }
    
    private func scheduleUpdate() {
        guard !updateScheduled else { return }
        
        updateScheduled = true
        valueQueue.asyncAfter(deadline: .now() + .milliseconds(16)) { [weak self] in
            guard let self else { return }
            
            self.updateScheduled = false
            DispatchQueue.main.async {
                self.updateTrigger.send()
            }
        }
    }
    
    private func combinedFaderValues() -> [Double] {
        var combined = Array(repeating: 0.0, count: 36)
        let aRatio = (100.0 - crossFaderValue) / 100.0
        let bRatio = crossFaderValue / 100.0
        
        for i in 0..<36 {
            if aFlashing[i] || bFlashing[i] {
                combined[i] = 100.0
            } else {
                let aLevel = aValues[i] * aRatio
                let bLevel = bValues[i] * bRatio
                combined[i] = min(100.0, aLevel + bLevel)
            }
        }
        return combined
    }
}
