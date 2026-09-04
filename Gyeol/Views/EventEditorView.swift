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
    @StateObject private var finder = DayPhotoFinder()
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

                    dayPhotos

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(directPickLabel, systemImage: "photo.on.rectangle")
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
            .onChange(of: date) { _, _ in finder.reset() }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task { await load(item) }
            }
            .confirmationDialog("이 사건을 삭제할까요?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("삭제", role: .destructive, action: delete)
            }
        }
    }

    private var directPickLabel: String {
        if isLoadingPhoto { return "불러오는 중…" }
        return photoData == nil ? "직접 찾기" : "사진 바꾸기"
    }

    /// Offers the photos already sitting in the library for this card's date, then hands
    /// off to the full picker below.
    @ViewBuilder
    private var dayPhotos: some View {
        switch finder.state {
        case .idle:
            Button {
                Task { await finder.find(on: date) }
            } label: {
                Label("관련된 사진 찾기", systemImage: "sparkle.magnifyingglass")
            }
            .disabled(isLoadingPhoto)

        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("\(date.nodeDateLabel)에 찍은 사진을 찾는 중…")
                    .foregroundStyle(.secondary)
            }

        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("사진 접근이 꺼져 있어 이 날 찍은 사진을 찾을 수 없어요.\n아래에서 직접 고를 수는 있어요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("설정에서 허용") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.footnote)
            }

        case .loaded(let photos):
            if photos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(date.nodeDateLabel)에 찍은 사진이 없어요.")
                        .font(.footnote)
                    Text("아래에서 직접 찾아보세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(date.nodeDateLabel)에 찍은 사진 \(photos.count)장")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(photos) { photo in
                                Button {
                                    Task { await choose(photo) }
                                } label: {
                                    Image(uiImage: photo.thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 78, height: 78)
                                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("이 사진 사용")
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .disabled(isLoadingPhoto)
                .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 0))
            }
        }
    }

    private func choose(_ photo: DayPhoto) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        if let data = await finder.photoData(for: photo) {
            photoData = data
            pickerItem = nil
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
