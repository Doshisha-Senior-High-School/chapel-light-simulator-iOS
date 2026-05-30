import SwiftUI

struct CrossFaderView: View {
    @ObservedObject var state: CrossFaderState
    
    var body: some View {
        VStack(spacing: 4) {
            Text("B")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
            
            GeometryReader { geometry in
                let trackHeight = geometry.size.height
                let knobHeight: CGFloat = 40
                let usableHeight = max(0, trackHeight - knobHeight)
                let currentOffset = CGFloat(state.value / 100.0) * usableHeight
                
                ZStack(alignment: .bottom) {
                    // 背景トラック
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 4)
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    
                    // つまみ
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 44, height: knobHeight)
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.8))
                                .frame(height: 2)
                        )
                        .offset(y: -currentOffset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let posFromBottom = trackHeight - drag.location.y - (knobHeight / 2)
                            let clampedOffset = max(0, min(usableHeight, posFromBottom))
                            let percentage = (clampedOffset / usableHeight) * 100.0
                            
                            DispatchQueue.main.async {
                                state.value = percentage
                            }
                        }
                )
            }
            
            Text("A")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(.vertical, 4)
        .frame(width: 50)
        .background(Color(UIColor.systemGray5))
        .border(Color.gray.opacity(0.4), width: 1)
    }
}
