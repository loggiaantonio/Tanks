
//
//  ChuckNorrisViewModel.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 05.09.24.
//

import Foundation

class ChuckNorrisViewModel: ObservableObject {
    @Published var joke: ChuckNorrisJoke?
    
    func fetchJoke() {
        guard let url = URL(string: "https://api.chucknorris.io/jokes/random") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(ChuckNorrisJoke.self, from: data)
                    DispatchQueue.main.async {
                        self.joke = decodedResponse
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            } else if let error = error {
                print("Error fetching joke: \(error.localizedDescription)")
            }
        }.resume()
    }
}
