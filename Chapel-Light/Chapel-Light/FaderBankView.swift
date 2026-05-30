import SwiftUI

struct FaderBankView: View {
    @ObservedObject var controller: LightingController
    let bankType: String // "A" or "B"
    
    var body: some View {
        HStack(spacing: 0) {
            // 左側のラベル
            VStack {
                Spacer()
                Text(bankType == "B" ? "Ｂ" : "Ａ")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                Spacer()
            }
            .frame(width: 24)
            .background(Color(UIColor.systemGray5))
            .border(Color.gray.opacity(0.4), width: 1)
            
            // フェーダーエリア (スクロールなし)
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    if index == 12 || index == 24 {
                        Spacer().frame(width: 4)
                    }
                    
                    FaderView(
                        index: index,
                        state: bankType == "A" ? controller.aFaders[index] : controller.bFaders[index],
                        label: controller.lightDefinitions[index],
                        bankType: bankType,
                        onValueChanged: { value in
                            controller.setFaderValue(value, bankType: bankType, index: index)
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }
}
