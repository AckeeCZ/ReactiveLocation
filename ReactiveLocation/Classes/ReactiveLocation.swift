import CoreLocation
import ReactiveCocoa
import Result

public enum LocationError: ErrorType {
    case LocationError(CLError)
}

public enum RegionState {
    case Enter(CLRegion)
    case Exit(CLRegion)
}

public enum LocationAuthorizationLevel {
    case WhenInUse
    case Always
}

public func < (lhs: LocationAuthorizationLevel, rhs: LocationAuthorizationLevel) -> Bool {
    return lhs == .WhenInUse && rhs == .Always
}
extension LocationAuthorizationLevel: Comparable { }

public extension LocationAuthorizationLevel {
    init?(status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways: self = .Always
        case .AuthorizedWhenInUse: self = .WhenInUse
        default: return nil
        }
    }
}

public enum LocationAuthorizationError: ErrorType {
    case Denied
    case Restricted
}
public protocol ReactiveLocationService {
    static func locationProducer(managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLLocation, LocationError>
    static func singleLocationProducer(managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLLocation, LocationError>
    static func visitProducer(managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLVisit, LocationError>
    static func regionProducer(region: CLRegion, managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<RegionState, LocationError>
    static func headingProducer(managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLHeading, LocationError>
    static var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> { get }
}

extension ReactiveLocationService {
    static func locationProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
        return locationProducer(managerFactory)
    }
    static func singleLocationProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
        return singleLocationProducer(managerFactory)
    }
    static func visitProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLVisit, LocationError> {
        return visitProducer(managerFactory)
    }
    static func regionProducer(region: CLRegion, managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<RegionState, LocationError> {
        return regionProducer(region, managerFactory: managerFactory)
    }
    static func headingProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLHeading, LocationError> {
        return headingProducer(managerFactory)
    }
}

extension CLLocationManager {

    private struct AssociatedKeys {
        static var DescriptiveName = "ack_delegate"
    }

    var delegateObject: NSObject? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveName) as? NSObject
        }

        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.DescriptiveName,
                    newValue as NSObject?,
                        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
        }
    }
}

public class ReactiveLocation: ReactiveLocationService {

    public init() { }

    static public func locationProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
        let manager = locationManagerFactory()
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return merge([errorSignal(delegateObject), locationSignal(delegateObject)])
            .on(started: {
                manager.startUpdatingLocation()
                }, terminated: {
                manager.stopUpdatingLocation()
        })
    }

    static public func singleLocationProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {

        let manager = locationManagerFactory()
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }

        // -requestLocation guarantees callback called once
        return merge([errorSignal(delegateObject), locationSignal(delegateObject)]).take(1)
            .on(started: {
                if #available(iOS 9, *) {
                    manager.requestLocation()
                } else {
                    manager.startUpdatingLocation()
                }
                }, terminated: {
                manager.stopUpdatingLocation()
        })
    }

    static public func headingProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLHeading, LocationError> {
        let manager = locationManagerFactory()
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return merge([errorSignal(delegateObject), headingSignal(delegateObject)])
            .on(started: {
                manager.startUpdatingHeading()
                }, terminated: {
                manager.stopUpdatingHeading()
        })
    }

    static public func visitProducer(managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLVisit, LocationError> {
        let manager = locationManagerFactory()
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return merge([errorSignal(delegateObject), visitSignal(delegateObject)])
            .on(started: {
                manager.startMonitoringVisits()
                }, terminated: {
                manager.stopMonitoringVisits()
        })
    }

    static public func regionProducer(region: CLRegion, managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<RegionState, LocationError> {
        let manager = locationManagerFactory()
        managerFactory?(manager)
        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return merge([errorSignal(delegateObject), regionSignal(delegateObject, regionState: .Exit(region)), regionSignal(delegateObject, regionState: .Enter(region))])
            .on(started: {
                manager.startMonitoringForRegion(region)
                }, terminated: {
                manager.stopMonitoringForRegion(region)
        })
    }

    static public let authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> =

    Action { targetLevel in
        let translateStatus: CLAuthorizationStatus -> SignalProducer <LocationAuthorizationLevel, LocationAuthorizationError> = { status in
            if let level = LocationAuthorizationLevel(status: status)
            where level >= targetLevel {
                return SignalProducer(value: level)
            } else {
                switch status {
                case .Restricted: return SignalProducer(error: .Restricted)
                case .Denied: return SignalProducer(error: .Denied)
                default:
                    assertionFailure("CLAuthorizationStatus shouldnt be .NotDetermined by now, maybe someone changed authorizationStatus from the outside?")
                    return SignalProducer(error: .Restricted)
                }
            }
        }

        let cl = ReactiveLocation.locationManagerFactory()
        return SignalProducer<CLAuthorizationStatus, NoError> { sink, dis in

            sink.sendNext(CLLocationManager.authorizationStatus()); sink.sendCompleted()
        }
            .promoteErrors(LocationAuthorizationError)
            .flatMap(.Latest) { status -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> in
                if case .NotDetermined = status {
                    return cl.delegateObject!.rac_signalForSelector(#selector(CLLocationManagerDelegate.locationManager(_: didChangeAuthorizationStatus:)), fromProtocol: CLLocationManagerDelegate.self)
                        .toSignalProducer()
                        .flatMapError { _ in SignalProducer.empty }
                        .on(started: {
                            switch targetLevel {
                            case .Always: cl.requestAlwaysAuthorization()
                            case .WhenInUse: cl.requestWhenInUseAuthorization()
                            }
                    })
                        .map { return CLAuthorizationStatus(rawValue: Int32(($0 as! RACTuple).second as! Int))! }
                        .filter { $0 != .NotDetermined }
                    // the delegate gets called with the current value after calling requestAuthorization, before the user selects an option, so we have to filter out this first value, TODO: refactor this
                    .take(1)
                        .promoteErrors(LocationAuthorizationError)
                        .flatMap(.Latest, transform: translateStatus)
                } else {
                    return translateStatus(status)
                }
        }
    }

    // MARK: Internal

    private class LocationDelegate: NSObject, CLLocationManagerDelegate {
        @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        }

        @objc func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        }

        @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        }

        func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        }

        func locationManager(manager: CLLocationManager, didVisit visit: CLVisit) {
        }

        func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        }

        func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        }
    }

    static private func errorSignal<T>(delegateObject: NSObject) -> SignalProducer<T, LocationError> {
        return delegateObject.rac_signalForSelector(#selector(CLLocationManagerDelegate.locationManager(_: didFailWithError:)), fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in SignalProducer.empty }
            .map { val in
                let error = (val as! RACTuple).second as! NSError
                return CLError(rawValue: error.code)!
        }
            .promoteErrors(LocationError)
            .flatMap(.Latest) { (error) in
                return SignalProducer<T, LocationError>(error: .LocationError(error))
        }
    }

    static private func locationSignal(delegateObject: NSObject) -> SignalProducer<CLLocation, LocationError> {
        return delegateObject.rac_signalForSelector(#selector(CLLocationManagerDelegate.locationManager(_: didUpdateLocations:)), fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in SignalProducer.empty }
            .promoteErrors(LocationError)
            .map { (($0 as! RACTuple).second as! [CLLocation]).last! }
    }

    static private func headingSignal(delegateObject: NSObject) -> SignalProducer<CLHeading, LocationError> {
        return delegateObject.rac_signalForSelector(#selector(CLLocationManagerDelegate.locationManager(_: didUpdateHeading:)), fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in SignalProducer.empty }
            .promoteErrors(LocationError)
            .map { (($0 as! RACTuple).second as! CLHeading) }
    }

    static private func visitSignal(delegateObject: NSObject) -> SignalProducer<CLVisit, LocationError> {
        return delegateObject.rac_signalForSelector(#selector(CLLocationManagerDelegate.locationManager(_: didVisit:)), fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in SignalProducer.empty }
            .promoteErrors(LocationError)
            .map { (($0 as! RACTuple).second as! CLVisit) }
    }

    static private func regionSignal(delegateObject: NSObject, regionState: RegionState) -> SignalProducer<RegionState, LocationError> {

        var selector = #selector(CLLocationManagerDelegate.locationManager(_: didEnterRegion:))
        if case .Exit = regionState {
            selector = #selector(CLLocationManagerDelegate.locationManager(_: didExitRegion:))
        }

        return delegateObject.rac_signalForSelector(selector, fromProtocol: CLLocationManagerDelegate.self)
            .toSignalProducer()
            .flatMapError { _ in SignalProducer.empty }
            .promoteErrors(LocationError)
            .map { (($0 as! RACTuple).second as! CLRegion) }
            .map { region in
                if case .Enter = regionState {
                    return .Enter(region)
                } else {
                    return .Exit(region)
                }
        }
    }

    static private func locationManagerFactory() -> CLLocationManager {
        let cl = CLLocationManager()
        let delegate = LocationDelegate()
        cl.delegate = delegate
        cl.delegateObject = delegate
        cl.desiredAccuracy = kCLLocationAccuracyBest
        return cl
    }

    static private func merge<T, E>(signals: [SignalProducer<T, E>]) -> SignalProducer<T, E> {
        let producers = SignalProducer<SignalProducer<T, E>, E>(values: signals)
        return producers.flatten(.Merge)
    }
}