import SwiftUI

struct CircleProgressView: View {
    @State private var progress: CGFloat = 0
    @State private var number: CGFloat = 0
    
    let duration: Double = 5.0
    let targetNumber: CGFloat = 10
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.2)
                .foregroundColor(.gray)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: duration), value: progress)
            
            // Number display
            Text("\(Int(number))")
                .font(.system(size: 50, weight: .bold))
                .animation(.linear(duration: duration), value: number)
        }
        .padding(40)
        .onAppear {
            // Start the animations
            withAnimation {
                progress = 1.0
                number = targetNumber
            }
        }
    }
}

struct CircleProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgressView()
    }
}