import SwiftUI

@main
struct TravelScheduleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-runAPIExamples") {
                        await APIExamples.run()
                    }
                    #endif
                }
        }
    }
}
