//
//  ColorPickerView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedColor: BlockColor
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(BlockColor.allCases) { color in
                        ColorOptionView(
                            color: color,
                            isSelected: selectedColor == color
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedColor = color
                            }
                            // Provide haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()

                            // Dismiss after short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Color Option View

struct ColorOptionView: View {
    let color: BlockColor
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.color.opacity(0.4), radius: isSelected ? 8 : 4)

                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color.color.contrastingTextColor)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)

            Text(color.name)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Inline Color Picker (for forms)

struct InlineColorPicker: View {
    @Binding var selectedColor: BlockColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BlockColor.allCases) { color in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = color
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 36, height: 36)

                            if selectedColor == color {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(color.color.contrastingTextColor)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedColor: BlockColor = .blue

    ColorPickerView(selectedColor: $selectedColor)
}

#Preview("Inline Color Picker") {
    @Previewable @State var selectedColor: BlockColor = .blue

    VStack {
        InlineColorPicker(selectedColor: $selectedColor)
            .padding()

        Text("Selected: \(selectedColor.name)")
    }
}
