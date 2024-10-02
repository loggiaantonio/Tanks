import SwiftUI
import AVFoundation
import SDWebImageSwiftUI

struct StartView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isLoading = true
    @State private var offsetX: CGFloat = -200 // Startposition

    var body: some View {
        if isLoading {
            GeometryReader { geometry in
                ZStack {
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)

                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        Spacer()

                        Image("logo")
                            .resizable()
                            .frame(width: 500, height: 300)
                            .padding(.bottom, 20)

                        Spacer()

                        // Hier wird die GIF-Datei angezeigt und bewegt
                        AnimatedImage(name: "Rbsl.gif")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.2)
                            .offset(x: offsetX, y: -30) // Hebt das GIF höher
                            .onAppear {
                                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: true)) {
                                    offsetX = geometry.size.width * 0.4 // Endposition
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .onAppear {
                playBackgroundMusic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    stopBackgroundMusic() // Musik stoppen, bevor der View wechselt
                    isLoading = false
                }
            }
        } else {
            SelectScreenView()
        }
    }

    func playBackgroundMusic() {
        if let path = Bundle.main.path(forResource: "startScreen", ofType: "mp3") {
            let url = URL(fileURLWithPath: path)

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = 0
                audioPlayer?.volume = 0.02
                audioPlayer?.play()
            } catch {
                print("Fehler beim Laden und Abspielen der Musik: \(error.localizedDescription)")
            }
        }
    }

    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
