import SwiftUI

struct HitCounterView: View {
    @Environment(AppModel.self) private var appModel: AppModel
    @Binding var hits: Int
    private let lineWidth: CGFloat = 12
    private let fontSize: CGFloat = 75
    private let maxHits: Int = 18
    
    var progress: CGFloat {
        CGFloat(hits) / CGFloat(maxHits)
    }
    
    var body: some View {
        if hits < maxHits {
            ZStack {
                // Background circle
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .opacity(0.2)
                    .foregroundColor(.gray)
                    .frame(width: 120, height: 120)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: hits)
                    .frame(width: 120, height: 120)
                
                // Hit counter
                Text("\(hits)")
                    .font(.system(size: fontSize))
                    .foregroundColor(.white)
            }
            .frame(width: 160, height: 160)
            .padding(30)
            // .glassBackgroundEffect() // visionOS glass effect
        }
    }
}

//#Preview {
//    HitCounterView(hits: .constant(5))
//        .preferredColorScheme(.dark)
//}

