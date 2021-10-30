//
//  SearchCityController.swift
//  WeatherApp
//
//  Created by Phoebe Hu on 10/29/21.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import SwiftSpinner
import PromiseKit

class SearchCityController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //let arr = ["Seattle", "New York"]
    
    var cityInfoList : [CityInfo] = [CityInfo]()
    
    @IBOutlet weak var tblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText.count < 3) {
            return;
        }
        print(searchText);
        cityInfoList.removeAll()
        getCitiesFromSearch(searchText)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cityInfoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let cityInfo = cityInfoList[indexPath.row]
        let text = "\(cityInfo.localizedName) \(cityInfo.administrativeID), \(cityInfo.countryLocalizedName)"
        cell.textLabel?.text = text;
        return cell;
    }
    
    func getSearchURL(_ searchText : String) -> String{
            return locationSearchURL + "apikey=" + apiKey + "&q=" + searchText
    }
    
    func getCitiesFromSearch(_ searchText: String){
        let url = getSearchURL(searchText)
                AF.request(url).responseJSON { response in
                    if response.error != nil {
                        print(response.error?.localizedDescription)
                    }
                    
                    if response.data == nil {
                        return
                    }
                    let cities = JSON(response.data)
                    for (_, city):(String, JSON) in cities {
                        let cityInfo = CityInfo()
                        cityInfo.key = city["Key"].stringValue
                        cityInfo.administrativeID = city["AdministrativeArea"]["ID"].stringValue
                        cityInfo.countryLocalizedName = city["Country"]["LocalizedName"].stringValue
                        cityInfo.localizedName = city["LocalizedName"].stringValue
                        cityInfo.type = city["Type"].stringValue
                        self.cityInfoList.append(cityInfo)
                    }
                    self.tblView.reloadData()
                }
    }
    
    func addCityinDB(_ cityInfo : CityInfo){
            do{
                let realm = try Realm()
                try realm.write {
                    realm.add(cityInfo, update: .modified)
                }
            }catch{
                print("Error in inserting values into DB \(error)")
            }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // You will get the Index of the city info from here and then add it into the realm Database
        // Once the city is added in the realm DB pop the navigation view controller
        let cityInfo = cityInfoList[indexPath.row]
        addCityinDB(cityInfo)
        self.navigationController?.popViewController(animated: true)
    }

}
