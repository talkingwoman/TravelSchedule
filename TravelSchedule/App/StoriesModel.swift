import Combine
import Foundation

@MainActor
final class StoriesModel: ObservableObject {
    @Published private(set) var index = 0
    @Published private(set) var progress = 0.0
    @Published private(set) var isFinished = false

    private let count: Int
    private let duration: TimeInterval = 10
    private var elapsed: TimeInterval = 0
    private var lastTick: Date?
    private var timer: AnyCancellable?

    init(count: Int) {
        self.count = max(0, count)
        isFinished = count <= 0
    }

    func start() {
        guard timer == nil, !isFinished else { return }
        lastTick = Date()
        timer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self, let lastTick = self.lastTick else { return }
                self.lastTick = date
                self.advance(by: date.timeIntervalSince(lastTick))
            }
    }

    func pause() {
        timer?.cancel()
        timer = nil
        lastTick = nil
    }

    func next() {
        guard !isFinished else { return }
        guard index + 1 < count else {
            progress = 1
            isFinished = true
            pause()
            return
        }
        index += 1
        resetProgress()
    }

    func previous() {
        guard !isFinished else { return }
        index = max(0, index - 1)
        resetProgress()
    }

    func advance(by interval: TimeInterval) {
        guard !isFinished, interval > 0, interval.isFinite else { return }
        elapsed += interval
        if elapsed >= duration {
            next()
        } else {
            progress = elapsed / duration
        }
    }

    private func resetProgress() {
        elapsed = 0
        progress = 0
        lastTick = timer == nil ? nil : Date()
    }
}
