import SwiftUI
import SwiftData
import PhotosUI

struct EventEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let timeline: Timeline
    let event: TimelineEvent?
    /// Called after save (with the saved event) or delete (with nil).
    var onFinish: ((TimelineEvent?) -> Void)? = nil

    @State private var date: Date
    @State private var title: String
    @State private var note: String
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var confirmDelete = false
    @FocusState private var focused: Field?

    private enum Field { case title, note }
    private static let space = "eventEditor"

    init(timeline: Timeline, event: TimelineEvent?, onFinish: ((TimelineEvent?) -> Void)? = nil) {
        self.timeline = timeline
        self.event = event
        self.onFinish = onFinish
        _date = State(initialValue: event?.date ?? .now)
        _title = State(initialValue: event?.title ?? "")
        _note = State(initialValue: event?.note ?? "")
        _photoData = State(initialValue: event?.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("날짜", selection: $date, displayedComponents: .date)
                    TextField("무슨 일이 있었나요?", text: $title)
                        .focused($focused, equals: .title)
                        .keyboardInput(in: Self.space)
                        .submitLabel(.next)
                        .onSubmit { focused = .note }
                }
                Section("내용") {
                    TextEditor(text: $note)
                        .focused($focused, equals: .note)
                        .keyboardInput(in: Self.space)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("기억하고 싶은 것을 적어두세요")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8).padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                Section("사진") {
                    if let photoData, let image = UIImage(data: photoData) {
                        Color.clear
                            .frame(height: 180)
                            .overlay {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .listRowInsets(EdgeInsets())
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        if isLoadingPhoto {
                            Label("불러오는 중…", systemImage: "photo")
                        } else {
                            Label(photoData == nil ? "사진 선택" : "사진 바꾸기", systemImage: "photo")
                        }
                    }
                    .disabled(isLoadingPhoto)
                    if photoData != nil {
                        Button("사진 제거", role: .destructive) {
                            photoData = nil
                            pickerItem = nil
                        }
                    }
                }
                if event != nil {
                    Section {
                        Button("사건 삭제", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissesKeyboardOnOutsideTap(space: Self.space, isEditing: focused != nil) { focused = nil }
            .navigationTitle(event == nil ? "사건 추가" : "사건 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .disabled(isLoadingPhoto)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { focused = nil }
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task { await load(item) }
            }
            .confirmationDialog("이 사건을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive, action: delete)
            }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        guard let raw = try? await item.loadTransferable(type: Data.self) else { return }
        let compressed = await Task.detached(priority: .userInitiated) {
            ImageCompressor.jpeg(from: raw)
        }.value
        if let compressed { photoData = compressed }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let saved: TimelineEvent
        if let event {
            event.date = date
            event.title = trimmedTitle
            event.note = trimmedNote
            event.photoData = photoData
            saved = event
        } else {
            saved = TimelineEvent(date: date, title: trimmedTitle, note: trimmedNote, photoData: photoData)
            timeline.events.append(saved)
        }
        try? context.save()
        onFinish?(saved)
        dismiss()
    }

    private func delete() {
        guard let event else { return }
        context.delete(event)
        try? context.save()
        onFinish?(nil)
        dismiss()
    }
}
