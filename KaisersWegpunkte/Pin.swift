import UIKit
import MapKit

class Pin: MKPointAnnotation {
    var id: Int!
    var color: UIColor! {
        didSet {
            print("Pin : #\(String(describing: id)) changed from \(String(describing: oldValue)) to \(String(describing: color))")
        }
    }
}
