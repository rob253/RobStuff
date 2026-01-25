//
//  HourMarkerView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct HourMarkerView: View {
    let hour: Int
    let use24HourFormat: Bool
    let height: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(formattedHour)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: TimelineConstants.timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 8)
                .offset(y: -8)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gridLine)
                    .frame(height: 1)
                Spacer()
            }
        }
        .frame(height: height)
    }

    private var formattedHour: String {
        if use24HourFormat {
            return String(format: "%02d:00", hour)
        } else {
            if hour == 0 {
                return "12 AM"
            } else if hour < 12 {
                return "\(hour) AM"
            } else if hour == 12 {
                return "12 PM"
            } else {
                return "\(hour - 12) PM"
            }
        }
    }
}

// MARK: - Half Hour Marker

struct HalfHourMarkerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer()
                .frame(width: TimelineConstants.timeColumnWidth)
                .padding(.trailing, 8)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gridLine.opacity(0.5))
                    .frame(height: 1)
                Spacer()
            }
        }
        .frame(height: TimelineConstants.hourHeight / 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        HourMarkerView(hour: 9, use24HourFormat: false, height: 60)
        HourMarkerView(hour: 10, use24HourFormat: false, height: 60)
        HourMarkerView(hour: 11, use24HourFormat: false, height: 60)
        HourMarkerView(hour: 12, use24HourFormat: false, height: 60)
        HourMarkerView(hour: 13, use24HourFormat: false, height: 60)
    }
    .padding()
}
