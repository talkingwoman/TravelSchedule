import SwiftUI

struct StoryItem: Identifiable {
    static let count = 18

    let index: Int

    var id: Int { index }
    var imageName: String {
        let number = index + 1
        return number < 10 ? "Story0\(number)" : "Story\(number)"
    }
}

struct StoriesRow: View {
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<StoryItem.count, id: \.self) { index in
                    let story = StoryItem(index: index)
                    Button {
                        onSelect(index)
                    } label: {
                        Image(story.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 76, height: 136)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.blue, lineWidth: 3)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("История \(index + 1)")
                }
            }
        }
        .frame(height: 136)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StoryViewerView: View {
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(startIndex: Int) {
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image(StoryItem(index: currentIndex).imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.45), location: 0),
                        .init(color: .clear, location: 0.28),
                        .init(color: .clear, location: 0.72),
                        .init(color: .black.opacity(0.2), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: showPrevious)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: showNext)
                }
                .padding(.top, 96)

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(0..<StoryItem.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentIndex ? .white : .white.opacity(0.35))
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        Text("История \(currentIndex + 1) из \(StoryItem.count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(.black.opacity(0.35), in: Circle())
                        }
                        .accessibilityLabel("Закрыть истории")
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, max(geometry.safeAreaInsets.top, 16) + 8)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { value in
                        if value.translation.width < -40 {
                            showNext()
                        } else if value.translation.width > 40 {
                            showPrevious()
                        }
                    }
            )
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .task(id: currentIndex) {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            showNext()
        }
    }

    private func showPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func showNext() {
        guard currentIndex + 1 < StoryItem.count else {
            dismiss()
            return
        }
        currentIndex += 1
    }
}
