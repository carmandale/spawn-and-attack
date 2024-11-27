import SwiftUI

struct CircleProgressView: View {
    @Binding var hits: Int
    private let maxHits: Int = 10
    @State private var progress: CGFloat = 0
    @State private var lineWidth: CGFloat = 12
    @State private var fontSize: CGFloat = 75
    
    var body: some View {
        ZStack {
            // // Background with glass effect
            // RoundedRectangle(cornerRadius: 15)
            //     .fill(.clear)
            //     .frame(width: 160, height: 160)
            
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.2)
                .foregroundColor(.gray)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(hits) / CGFloat(maxHits))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: hits)
                .frame(width: 120, height: 120)
            
            Text("\(hits)")
                .font(.system(size: fontSize, weight: .bold))
        }
        .frame(width: 160, height: 160)
        .padding(30)
    }
}

struct CircleProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressView(hits: .constant(5))
    }
}
