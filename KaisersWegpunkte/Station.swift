import UIKit
import CoreLocation

struct Station {
    static let rad: Double = 50.0
    static var spentMoney: Double = 0
    
    static let red: UIColor! = UIColor.init(red: 1.0, green: 0.27, blue: 0.27, alpha: 1.0)
    static let green: UIColor! = UIColor.init(red: 0.29, green: 0.84, blue: 0.38, alpha: 1.0)
    static let grey: UIColor! = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
    
    var id: Int
    var title: String
    var task: String
    var cost: Double
    var coord: CLCircularRegion
    
    init(_ id: Int, _ title: String, _ task: String, _ cost: Double, _ latLng: [Double]) {
        self.id = id
        self.title = title
        self.task = task
        self.cost = cost
        self.coord = CLCircularRegion(center: CLLocationCoordinate2DMake(latLng[0], latLng[1]), radius: Station.rad, identifier: String(id))
    }
    
    mutating func visit() {
        Station.spentMoney = Station.spentMoney + self.cost
    }
}
