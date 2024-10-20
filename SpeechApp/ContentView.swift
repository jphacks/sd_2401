import SwiftUI
import CoreData

/*
struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ThemeSelectionView()) {
                    Text("好きなテーマ")
                }
                .padding()
                
                NavigationLink(destination: YouTubeView()) {
                    Text("YouTube")
                }
                .padding()
                
                NavigationLink(destination: NewsView()) {
                    Text("News")
                }
                .padding()
            }
        }
    }
}
*/

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ThemeSelectionView()) {
                    Text("好きなテーマ")
                }
                .padding()
                
                NavigationLink(destination: YouTubeView()) {
                    Text("YouTube")
                }
                .padding()
                
                NavigationLink(destination: NewsView()) {
                    Text("News")
                }
                .padding()
            }
        }
    }
}

struct ThemeSelectionView: View {
    var body: some View {
        Text("好きなテーマ画面")
    }
}

struct YouTubeView: View {
    var body: some View {
        Text("YouTube画面")
    }
}

struct NewsView: View {
    var body: some View {
        Text("News画面")
    }
}




struct ThemeSelectionView: View {
    var body: some View {
        Text("好きなテーマ画面")
    }
}

struct YouTubeView: View {
    var body: some View {
        Text("YouTube画面")
    }
}

struct NewsView: View {
    var body: some View {
        Text("News画面")
    }
}


