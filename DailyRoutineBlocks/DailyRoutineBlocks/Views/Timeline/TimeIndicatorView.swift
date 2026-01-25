//
//  TimeIndicatorView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct CurrentTimeIndicatorView: View {
    let yPosition: CGFloat
    let timeColumnWidth: CGFloat

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 0) {
            // Time label area spacer
            Spacer()
                .frame(width: timeColumnWidth - 8)

            // Circle indicator
            Circle()
                .fill(Color.currentTimeIndicator)
                .frame(width: 10, height: 10)
                .shadow(color: Color.currentTimeIndicator.opacity(0.5), radius: 4)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Line
            Rectangle()
                .fill(Color.currentTimeIndicator)
                .frame(height: 2)
                .shadow(color: Color.currentTimeIndicator.opacity(0.3), radius: 2)
        }
        .offset(y: yPosition - 5) // Center the indicator on the time
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemBackground)

        VStack {
            CurrentTimeIndicatorView(
                yPosition: 100,
                timeColumnWidth: 50
            )
            Spacer()
        }
    }
    .frame(height: 300)
}
