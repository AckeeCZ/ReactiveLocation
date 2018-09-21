import Foundation
import CoreLocation
import ReactiveSwift
import Result

internal class ReactiveLocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    
    private let didChangeAuthorizationStatusPipe = Signal<CLAuthorizationStatus, NoError>.pipe()
    internal lazy var didChangeAuthorizationStatus: Signal<CLAuthorizationStatus, NoError> = self.didChangeAuthorizationStatusPipe.0
    
    private let didFailPipe = Signal<Error, NoError>.pipe()
    internal lazy var didFail: Signal<Error, NoError> = self.didFailPipe.0
    
    private let didUpdateLocationsPipe = Signal<[CLLocation], NoError>.pipe()
    internal lazy var didUpdateLocations: Signal<[CLLocation], NoError> = self.didUpdateLocationsPipe.0
    
    private let didUpdateHeadingPipe = Signal<CLHeading, NoError>.pipe()
    internal lazy var didUpdateHeading: Signal<CLHeading, NoError> = self.didUpdateHeadingPipe.0
    
    private let didVisitPipe = Signal<CLVisit, NoError>.pipe()
    internal lazy var didVisit: Signal<CLVisit, NoError> = self.didVisitPipe.0
    
    private let didEnterRegionPipe = Signal<CLRegion,NoError>.pipe()
    internal lazy var didEnterRegion: Signal<CLRegion,NoError> = self.didEnterRegionPipe.0
    
    private let didExitRegionPipe = Signal<CLRegion,NoError>.pipe()
    internal lazy var didExitRegion: Signal<CLRegion,NoError> = self.didExitRegionPipe.0
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeAuthorizationStatusPipe.1.send(value: status)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        didFailPipe.1.send(value: error)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        didUpdateLocationsPipe.1.send(value: locations)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        didUpdateHeadingPipe.1.send(value: newHeading)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        didVisitPipe.1.send(value: visit)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        didEnterRegionPipe.1.send(value: region)
    }
    
    internal func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        didExitRegionPipe.1.send(value: region)
    }
}
