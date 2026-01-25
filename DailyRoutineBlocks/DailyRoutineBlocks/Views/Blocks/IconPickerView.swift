//
//  IconPickerView.swift
//  DailyRoutineBlocks
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filteredCategories: [(category: String, icons: [BlockIcon])] {
        if searchText.isEmpty {
            return BlockIcon.categorized
        }

        let lowercasedSearch = searchText.lowercased()
        return BlockIcon.categorized.compactMap { category, icons in
            let filteredIcons = icons.filter { icon in
                icon.rawValue.lowercased().contains(lowercasedSearch) ||
                category.lowercased().contains(lowercasedSearch)
            }
            return filteredIcons.isEmpty ? nil : (category, filteredIcons)
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // None option
                    if searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                selectedIcon = nil
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "circle.slash")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)

                                    Text("No Icon")
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedIcon == nil {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Icon categories
                    ForEach(filteredCategories, id: \.category) { category, icons in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(icons) { icon in
                                    IconOptionView(
                                        icon: icon,
                                        isSelected: selectedIcon == icon.symbolName
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedIcon = icon.symbolName
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if filteredCategories.isEmpty {
                        ContentUnavailableView(
                            "No Icons Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try a different search term")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .searchable(text: $searchText, prompt: "Search icons")
            .navigationTitle("Choose Icon")
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

// MARK: - Icon Option View

struct IconOptionView: View {
    let icon: BlockIcon
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .frame(width: 50, height: 50)

            Image(systemName: icon.symbolName)
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedIcon: String? = "figure.run"

    IconPickerView(selectedIcon: $selectedIcon)
}
