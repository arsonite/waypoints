import UIKit
import MapKit
import CoreLocation

class FirstViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var locationManager: CLLocationManager?
    
    var populated: Bool = false
    var stations: [Station] = []
    var i: Int = 0
    
    @IBOutlet weak var stationList: UITableView!

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var taskField: UITextField!
    @IBOutlet weak var costField: UITextField!
    
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var lngLabel: UILabel!
    
    @IBOutlet weak var map: MKMapView!
    
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
        
        /* Necessary delegates to ensure keyboard is closed when "return" is pressed */
        titleField.delegate = self
        taskField.delegate = self
        costField.delegate = self
        
        /* Swift 4.1 long-press-recogniser to create pins with touch gesture */
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(FirstViewController.handleLongPress(_:)))
        /* Minimum duration for pressing, here 1 sec */
        longPressRecogniser.minimumPressDuration = 1.0
        map.addGestureRecognizer(longPressRecogniser)
    }
    
    /* Creates a custom pin on the location the user touches the map on */
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer) {
        /* Deactivate this for funny bug ;) */
        if gestureRecognizer.state != .began { return }
        
        emptyLatLong()
        
        let pin = Pin()
        pin.color = Station.red
        pin.coordinate = map.convert(gestureRecognizer.location(in: map), toCoordinateFrom: map)
        map.addAnnotation(pin)
        
        latLabel.text = String(pin.coordinate.latitude)
        lngLabel.text = String(pin.coordinate.longitude)
    }
    
    func emptyLatLong() {
        print(map.annotations)
        
        map.removeAnnotations(map.annotations)
        latLabel.text = ""
        lngLabel.text = ""
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        /* Prevents the user location pin to change as well */
        guard let pin = annotation as? Pin else { return nil }
        
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "self")
        annotationView.pinTintColor = pin.color
        annotationView.animatesDrop = true
        return annotationView
    }
    
    func fillTable() {
        i = i + 1
        stationList.beginUpdates()
        stationList.insertRows(at: [IndexPath(row: stations.count-1, section: 0)], with: .automatic)
        stationList.endUpdates()
    }
    
    /* Prepares data for segue to ViewController */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! ViewController
        controller.stations = stations
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
        cell.backgroundColor = Station.grey
        cell.textLabel?.text = stations[indexPath.row].title
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    /* Allows the user to swipe left and delete single UITableViewCells
     * and delete the correspondent value in the array
     */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.stations.remove(at: indexPath.row)
            self.stationList.deleteRows(at: [indexPath], with: .automatic)
            Toast.success("Deleted station", self)
        }
    }
    
    /* Function to close keyboard when return key is pressed */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func switchMap(_ sender: Any) {
        performSegue(withIdentifier: "segue", sender: self)
    }
    
    /* Button-functionality to add stations to the station-array and the UITableView */
    @IBAction func addStation(_ sender: Any) {
        if titleField.text! == "" || taskField.text! == "" || costField.text! == "" {
            Toast.warning("Not all fields filled out", self)
            return
        } else if latLabel.text! == "" {
            Toast.warning("Not created a pin", self)
            return
        }
        
        let coord = map.annotations[0].coordinate
        
        let station = Station(i, titleField.text!, taskField.text!, Double(costField.text!)!, [coord.latitude, coord.longitude])
        stations.append(station)
        
        clearStation("")
        fillTable()
        Toast.success("Station added", self)
    }
    
    /* Button-functionality to populate the UITableView with the template-values from task 7 */
    @IBAction func populateTable(_ sender: Any) {
        if populated {
            Toast.warning("Already added template stations", self)
            return
        }
        Toast.info("Added 6 template stations", self)
        
        let dict: [(Int, String, String, Double, [Double])] = [(i, "Tankstelle", "Volltanken", 45.38, [52.504947, 13.338505]), (i + 1, "Dr. Med. Skolova", "Blutabnahme", 0, [52.503184, 13.348501]), (i + 2, "Bäckerei Steinke", "Brötchen kaufen", 5.95, [52.506419, 13.352014]), (i + 3, "Zeitungsladen", "Morgenpost kaufen", 1.25, [52.511162, 13.350789]), (i + 4, "Nanu-Nana", "Geschenk für Sophie", 9.99, [52.516506, 13.353914]), (i + 5, "Altersheim", "Mutti besuchen", 0, [52.517443, 13.367782])]
        
        for d in dict {
            stations.append(Station(d.0, d.1, d.2, d.3, d.4))
            fillTable()
        }
        populated = true
    }
    
    /* Button-functionality to clear all the input in the view and the custom pin on the map */
    @IBAction func clearStation(_ sender: Any) {
        titleField.text = ""
        taskField.text = ""
        costField.text = ""
        
        emptyLatLong()
        
        Toast.info("Cleared all fields", self)
    }
    
    /* Button-functionality to toggle the bus-route of the Berlin100 simulation on the map */
    @IBAction func toggleBusRoute(_ sender: Any) {
    }
}
