import SwiftUI

struct ContentView: View {
    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
