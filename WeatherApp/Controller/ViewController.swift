//
//  ViewController.swift
//  WeatherApp
//
//  Created by Phoebe Hu on 10/28/21.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import SwiftSpinner
import PromiseKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var currentWeatherList: [CurrentWeather] = [CurrentWeather]()
    //let arr = ["Seattle", "New York"]

    @IBOutlet weak var tblView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadCurrentConditions()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentWeatherList.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let currentWeather = currentWeatherList[indexPath.row]
        let text = "\(currentWeather.cityInfoName) \(currentWeather.temp)℉ \(currentWeather.weatherText)"
        cell.textLabel?.text = text
        return cell;
    }
    
    func loadCurrentConditions() {
        print(Realm.Configuration.defaultConfiguration.fileURL!);
        do{
                   let realm = try Realm()
                   let cities = realm.objects(CityInfo.self)
                   
                   if cities.count == 0 {
                       return
                   }
                   getAllCurrentWeather(Array(cities)).done { currentWeatherList in
                       self.currentWeatherList = currentWeatherList
                       self.tblView.reloadData()
                   }
                   .catch { error in
                        print(error)
                    }
               }catch{
                   print("Error in reading Database \(error)")
               }
    }
    
    func getAllCurrentWeather(_ cities: [CityInfo] ) -> Promise<[CurrentWeather]> {
            var promises: [Promise< CurrentWeather >] = []
            
            for i in 0 ... cities.count - 1 {
                promises.append( getCurrentWeather(cities[i]) )
            }
            
            return when(fulfilled: promises)
        }
        
        func getCurrentWeather(_ city : CityInfo) -> Promise<CurrentWeather>{
            return Promise<CurrentWeather> { seal -> Void in
                let url = "\(currentConditionURL)\(city.key)?apikey=\(apiKey)"
                
                AF.request(url).responseJSON { response in
                    
                    if response.error != nil {
                        seal.reject(response.error!)
                    }
                    
                    let (_, json) = JSON(response.data!).first!
                    print(json)
                    let currentWeather = CurrentWeather()
                    
                    currentWeather.temp = json["Temperature"]["Imperial"]["Value"].intValue
                    currentWeather.epochTime = json["EpochTime"].intValue
                    currentWeather.isDayTime = json["IsDayTime"].boolValue
                    currentWeather.weatherText = json["WeatherText"].stringValue
                    currentWeather.cityKey = city.key
                    currentWeather.cityInfoName = city.localizedName

                    seal.fulfill(currentWeather)
                }
            }
        }

}

