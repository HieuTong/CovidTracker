//
//  APICaller.swift
//  CovidTracker
//
//  Created by HieuTong on 6/8/21.
//

import Foundation

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
    
    static let prettyFomatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter
    }()
}

class APICaller {
    static let shared = APICaller()
    
    private init() {}
    
    private struct Constants {
        static let allStatesUrl = URL(string: "https://api.covidtracking.com/v2/states.json")
        
    }
    
    enum DateScope {
        case national
        case state(State)
    }
    
    public func getCovidData(for scope: DateScope, completion: @escaping (Result<[DayData], Error>) -> Void) {
        let urlString: String = {
            switch scope {
            case .national:
                return "https://api.covidtracking.com/v2/us/daily.json"
            case .state(let state):
                return "https://api.covidtracking.com/v2/states/\(state.state_code)/daily.json"
            }
        }()
        
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else { return }
            do {
                let decode = JSONDecoder()
                let result = try decode.decode(CovidDataResponse.self, from: data)
                
                let models: [DayData] = result.data.compactMap {
                    guard let date = DateFormatter.dayFormatter.date(from: $0.date), let value = $0.cases?.total.value else { return nil }
                    return DayData(date: date, count: value)
                }
                
                completion(.success(models))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    public func getStateList(completion: @escaping (Result<[State], Error>) -> Void) {
        guard let url = Constants.allStatesUrl else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else { return }
            do {
                let decode = JSONDecoder()
                let result = try decode.decode(StateListReponse.self, from: data)
                let states = result.data
                completion(.success(states))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

//MARK: - Models

struct StateListReponse: Codable {
    let data: [State]
}

struct State: Codable {
    let name: String
    let state_code: String
}

struct CovidDataResponse: Codable {
    let data: [CovidDayData]
}

struct CovidDayData: Codable {
    let cases: CovidCases?
    let date: String
}

struct CovidCases: Codable {
    let total: TotalCases
}

struct TotalCases: Codable {
    let value: Int?
}

struct DayData {
    let date: Date
    let count: Int
}
