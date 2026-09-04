import SwiftUI
import SwiftData

struct TimelineEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var existing: [Timeline]

    let timeline: Timeline?

    @State private var name: String
    @State private var colorHex: String
    @FocusState private var isNameFocused: Bool
    private static let space = "timelineEditor"

    init(timeline: Timeline?) {
        self.timeline = timeline
        _name = State(initialValue: timeline?.name ?? "")
        _colorHex = State(initialValue: timeline?.colorHex ?? TimelinePalette.hexes[0])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("예: 우리 아이 첫 해, 앱 출시 기록", text: $name)
                        .focused($isNameFocused)
                        .keyboardInput(in: Self.space)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
                Section("색") {
                    HStack(spacing: 14) {
                        ForEach(TimelinePalette.hexes, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        Circle().strokeBorder(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                                            .padding(-4)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(hex)
                            .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnOutsideTap(space: Self.space, isEditing: isNameFocused) { isNameFocused = false }
            .navigationTitle(timeline == nil ? "새 타임라인" : "타임라인 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(timeline == nil ? "만들기" : "저장", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { isNameFocused = false }
                }
            }
            .onAppear {
                if timeline == nil { colorHex = TimelinePalette.next(after: existing.count) }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let timeline {
            timeline.name = trimmed
            timeline.colorHex = colorHex
        } else {
            context.insert(Timeline(name: trimmed, colorHex: colorHex))
        }
        try? context.save()
        dismiss()
    }
}
