import SwiftUI

struct StoryItem: Identifiable {
    let id: Int
    let title = "Text Text Text Text Text Text Text Text Text Text"
    let description = "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text"

    var imageName: String { String(format: "Story%02d", id) }
}

struct StoryCollection: Identifiable {
    let id: Int
    let slides: [StoryItem]

    static let all: [StoryCollection] = [
        [1, 2, 6], [3, 4, 5], [11, 12], [7, 8],
        [9, 10], [13, 14], [15, 16], [17, 18]
    ].enumerated().map { index, images in
        StoryCollection(id: index, slides: images.map { StoryItem(id: $0) })
    }
}

struct StoriesRow: View {
    let viewedIDs: Set<Int>
    let onSelect: (StoryCollection) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StoryCollection.all) { collection in
                    if let preview = collection.slides.first {
                        Button {
                            onSelect(collection)
                        } label: {
                            Image(preview.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 92, height: 140)
                                .overlay {
                                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                                }
                                .opacity(viewedIDs.contains(collection.id) ? 0.5 : 1)
                                .overlay(alignment: .bottomLeading) {
                                    Text(preview.title)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                        .lineLimit(3)
                                        .padding(8)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay {
                                    if !viewedIDs.contains(collection.id) {
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(TravelStyle.blue, lineWidth: 4)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("История \(collection.id + 1)")
                        .accessibilityValue(viewedIDs.contains(collection.id) ? "Просмотрена" : "Не просмотрена")
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
    }
}

struct StoryViewerView: View {
    let collection: StoryCollection
    let isPaused: Bool
    let onClose: () -> Void

    @StateObject private var model: StoriesModel
    @State private var dragOffset: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(collection: StoryCollection, isPaused: Bool, onClose: @escaping () -> Void) {
        self.collection = collection
        self.isPaused = isPaused
        self.onClose = onClose
        _model = StateObject(wrappedValue: StoriesModel(count: collection.slides.count))
    }

    var body: some View {
        GeometryReader { geometry in
            if collection.slides.indices.contains(model.index) {
                let story = collection.slides[model.index]
                ZStack {
                    Image(story.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .center, endPoint: .bottom)

                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()
                        Text(story.title)
                            .font(.system(size: 34, weight: .bold))
                            .lineLimit(2)
                        Text(story.description)
                            .font(.system(size: 20))
                            .lineLimit(3)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .allowsHitTesting(false)

                    HStack(spacing: 0) {
                        navigationArea("Предыдущая история", action: model.previous)
                        navigationArea("Следующая история", action: model.next)
                    }

                    VStack(spacing: 8) {
                        StoriesProgressView(count: collection.slides.count, index: model.index, progress: model.progress)
                            .padding(.horizontal, 12)
                        HStack {
                            Spacer()
                            Button(action: close) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(TravelStyle.black, in: Circle())
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Закрыть истории")
                        }
                        .padding(.trailing, 5)
                        Spacer()
                    }
                    .padding(.top, 28)
                }
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .offset(y: dragOffset)
                .simultaneousGesture(swipe)
            }
        }
        .padding(.top, 7)
        .padding(.bottom, 17)
        .background(TravelStyle.black.ignoresSafeArea())
        .onAppear {
            if model.isFinished { close() } else { updateTimer() }
        }
        .onDisappear { model.pause() }
        .onChange(of: scenePhase) { _, _ in updateTimer() }
        .onChange(of: isPaused) { _, _ in updateTimer() }
        .onChange(of: model.isFinished) { _, finished in
            if finished { close() }
        }
        .accessibilityAction(.escape, close)
    }

    private func navigationArea(_ title: String, action: @escaping () -> Void) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                model.pause()
                if value.translation.height > abs(value.translation.width) {
                    dragOffset = max(0, value.translation.height)
                }
            }
            .onEnded { value in
                let movement = value.translation
                if movement.height > 80 && movement.height > abs(movement.width) {
                    close()
                    return
                }
                if abs(movement.width) > abs(movement.height) {
                    if movement.width < -40 { model.next() }
                    if movement.width > 40 { model.previous() }
                }
                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) { dragOffset = 0 }
                updateTimer()
            }
    }

    private func updateTimer() {
        if scenePhase == .active && !isPaused { model.start() } else { model.pause() }
    }

    private func close() {
        model.pause()
        onClose()
    }
}

private struct StoriesProgressView: View {
    let count: Int
    let index: Int
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { segment in
                GeometryReader { geometry in
                    let fraction = segment < index ? 1 : (segment == index ? progress : 0)
                    Color.white
                        .overlay(alignment: .leading) {
                            TravelStyle.blue.frame(width: geometry.size.width * fraction)
                        }
                        .clipShape(Capsule())
                        .animation(reduceMotion || progress == 0 ? nil : .linear(duration: 0.05), value: fraction)
                }
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("История \(index + 1) из \(count)")
    }
}
