//
//  TankApi.swift
//  Tanks Arma Get On
//
//  Created by Antonio Loggia on 05.09.24.
//



import Foundation

class TankViewModel: ObservableObject {
    @Published var tanks: [Tanks] = []

    func fetchTanks() {
        guard let url = URL(string: "https://tanks.gg/list") else { return } // Die URL muss eine API sein
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([Tanks].self, from: data)
                    DispatchQueue.main.async {
                        self.tanks = decodedResponse
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            }
        }.resume()
    }
}
