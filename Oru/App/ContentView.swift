import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        if hasSeenWelcome {
            TabView {
                Text("Hábitos")
                    .tabItem {
                        Label("Hábitos", systemImage: "list.bullet")
                    }

                Text("Estadísticas")
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }

                Text("Gamificación")
                    .tabItem {
                        Label("Origamis", systemImage: "star")
                    }

                Text("Temporizador")
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
            }
        } else {
            WelcomeView {
                withAnimation {
                    hasSeenWelcome = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
