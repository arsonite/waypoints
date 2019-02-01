import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var locationManager: CLLocationManager?
    
    var i: Int! = 0
    var centered: Bool! = false
    
    var stations: [Station] = []
    
    let url = URL(fileURLWithPath: Bundle.main.path(forResource: "ding", ofType: "mp3")!)
    var avPlayer: AVAudioPlayer?
    
    @IBOutlet weak var log1: UILabel!
    @IBOutlet weak var log2: UILabel!
    @IBOutlet weak var add: UILabel!
    @IBOutlet weak var sum: UILabel!
    
    @IBOutlet weak var map: MKMapView!
        
    @IBOutlet weak var centerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* locationManager configuration */
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        
        /* MKMapView configuration */
        map.showsUserLocation = true;
        map.delegate = self;
        
        /* Registers pan-gesture-event-listener to the map */
        let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.didDragMap(gestureRecognizer:)))
        dragRecognizer.delegate = self
        self.map.addGestureRecognizer(dragRecognizer)
        
        for station in stations {
            station.coord.notifyOnEntry = true;
            station.coord.notifyOnExit = true;
            locationManager?.startMonitoring(for: station.coord)
            
            let pin = Pin()
            pin.coordinate = station.coord.center
            pin.title = station.title
            pin.subtitle = station.task
            pin.color = Station.red
            pin.id = station.id
            map.addAnnotation(pin)
        }
    }
    
    /* https://stackoverflow.com/questions/33405449/determine-if-mkmapview-was-dragged-moved-in-swift-2-0 */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func didDragMap(gestureRecognizer: UIGestureRecognizer) {
        centered = false
        centerButton.isHidden = false
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        /* Prevents the user location pin to change as well */
        guard let pin = annotation as? Pin else { return nil }
                
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(pin.id))
        annotationView.pinTintColor = pin.color
        annotationView.canShowCallout = true
        return annotationView
    }
    
    /* Overloading method through polymorphy */
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if(!centered) { return }
        
        centerUserPosition(userLocation.coordinate)
    }
    
    func centerUserPosition(_ userCoordinates: CLLocationCoordinate2D) {
        self.map.region = MKCoordinateRegion(center: userCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
    
    /* Overloading method through polymorphy */
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let index: Int = Int(region.identifier)!
        var station = stations[index]
        
        log1.text = station.title
        log2.text = station.task
        
        station.visit()
        playSound()
        add.text = "\(String(station.cost))€"
        sum.text = String(Station.spentMoney)
        
        if let cell = self.view.viewWithTag(station.id + 1) as? UITableViewCell {
            cell.backgroundColor = Station.green
        }
        
        for m in map.annotations {
            visitPin(m, index)
        }
    }
    
    /* Overloading method through polymorphy */
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        log1.text = ""
        log2.text = ""
        add.text = ""
        
        if let cell = self.view.viewWithTag(Int(region.identifier)! + 1) as? UITableViewCell {
            cell.backgroundColor = Station.grey
        }
        
        for m in map.annotations {
            leavePin(m)
        }
        
        i = i + 1
    }
    
    func visitPin(_ annotation: MKAnnotation, _ index: Int) {
        guard let pin = annotation as? Pin else { return }
        if pin.id != index { return }
        
        map.removeAnnotation(annotation)
        pin.color = Station.green
        map.addAnnotation(pin)
    }
    
    func leavePin(_ annotation: MKAnnotation) {
        guard let pin = annotation as? Pin else { return }
        if pin.id != i { return }
        
        map.removeAnnotation(annotation)
        pin.color = Station.grey
        map.addAnnotation(pin)
    }
    
    func playSound() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            avPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let aPlayer = avPlayer else { return }
            aPlayer.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /* Ensures that through synchronization delegate and datasource are always up to date */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stationsCell", for: indexPath)
        cell.backgroundColor = Station.red
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = stations[indexPath.row].title
        cell.tag = stations[indexPath.row].id + 1
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
    
    @IBAction func centrePosition(_ sender: Any) {
        centered = true
        centerUserPosition(map.userLocation.coordinate)
        centerButton.isHidden = true
    }
}
