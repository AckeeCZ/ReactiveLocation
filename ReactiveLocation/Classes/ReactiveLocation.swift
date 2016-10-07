import CoreLocation
import ReactiveSwift
import Result

public enum LocationError: Error {
    case locationError(CLError.Code)
}

public enum RegionState {
    case enter(CLRegion)
    case exit(CLRegion)
}

public enum LocationAuthorizationLevel {
    case whenInUse
    case always
}

public func < (lhs: LocationAuthorizationLevel, rhs: LocationAuthorizationLevel) -> Bool {
    return lhs == .whenInUse && rhs == .always
}
extension LocationAuthorizationLevel: Comparable { }

public extension LocationAuthorizationLevel {
    init?(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways: self = .always
        case .authorizedWhenInUse: self = .whenInUse
        default: return nil
        }
    }
}

public enum LocationAuthorizationError: Error {
    case denied
    case restricted
}
public protocol ReactiveLocationService {
    static func locationProducer(_ managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLLocation, LocationError>
    static func singleLocationProducer(_ managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLLocation, LocationError>
    static func visitProducer(_ managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLVisit, LocationError>
    static func regionProducer(_ region: CLRegion, managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<RegionState, LocationError>
    static func headingProducer(_ managerFactory: ((CLLocationManager) -> ())?) -> SignalProducer<CLHeading, LocationError>
    static var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> { get }
}

extension ReactiveLocationService {
    static func locationProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
        return locationProducer(managerFactory)
    }
    static func singleLocationProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
        return singleLocationProducer(managerFactory)
    }
    static func visitProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLVisit, LocationError> {
        return visitProducer(managerFactory)
    }
    static func regionProducer(_ region: CLRegion, managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<RegionState, LocationError> {
        return regionProducer(region, managerFactory: managerFactory)
    }
    static func headingProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLHeading, LocationError> {
        return headingProducer(managerFactory)
    }
}

extension CLLocationManager {

    fileprivate struct AssociatedKeys {
        static var DescriptiveName = "ack_delegate"
    }

    var delegateObject: ReactiveLocationManagerDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.DescriptiveName) as? ReactiveLocationManagerDelegate
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

open class ReactiveLocation: ReactiveLocationService {

    public init() { }

    static open func locationProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {
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

    static open func singleLocationProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLLocation, LocationError> {

        let manager = locationManagerFactory()
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }

        // -requestLocation guarantees callback called once
        return merge([errorSignal(delegateObject), locationSignal(delegateObject)]).take(first: 1)
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

    static open func headingProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLHeading, LocationError> {
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

    static open func visitProducer(_ managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<CLVisit, LocationError> {
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

    static open func regionProducer(_ region: CLRegion, managerFactory: ((CLLocationManager) -> ())? = nil) -> SignalProducer<RegionState, LocationError> {
        let manager = locationManagerFactory()
        managerFactory?(manager)
        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        let enter = regionSignal(delegateObject, regionState: .exit(region))
        let error: SignalProducer<RegionState, LocationError> = errorSignal(delegateObject)
        let exit = regionSignal(delegateObject, regionState: .enter(region))
        return merge([enter, exit, error])
            .on(started: {
                manager.startMonitoring(for: region)
                }, terminated: {
                    manager.stopMonitoring(for: region)
        })
    }

    static open let authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> =

    Action { targetLevel in
        let translateStatus: (CLAuthorizationStatus) -> SignalProducer <LocationAuthorizationLevel, LocationAuthorizationError> = { status in
            if let level = LocationAuthorizationLevel(status: status)
            , level >= targetLevel {
                return SignalProducer(value: level)
            } else {
                switch status {
                case .restricted: return SignalProducer(error: .restricted)
                case .denied: return SignalProducer(error: .denied)
                default:
                    assertionFailure("CLAuthorizationStatus shouldnt be .NotDetermined by now, maybe someone changed authorizationStatus from the outside?")
                    return SignalProducer(error: .restricted)
                }
            }
        }

        let cl = ReactiveLocation.locationManagerFactory()
        return SignalProducer<CLAuthorizationStatus, NoError> { sink, dis in

            sink.send(value: CLLocationManager.authorizationStatus())
            sink.sendCompleted()
        }
            .promoteErrors(LocationAuthorizationError)
            .flatMap(.latest) { status -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> in
                if case .notDetermined = status {
                    return SignalProducer(signal: cl.delegateObject!.didChangeAuthorizationStatus)
                        .on(started: {
                            switch targetLevel {
                            case .always: cl.requestAlwaysAuthorization()
                            case .whenInUse: cl.requestWhenInUseAuthorization()
                            }
                        })
                        .filter { $0 != .notDetermined }
                        .promoteErrors(LocationAuthorizationError)
                        .take(first: 1)
                        .flatMap(.latest, transform: translateStatus)
                } else {
                    return translateStatus(status)
                }
        }
    }

    // MARK: Internal

    static fileprivate func errorSignal<T>(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<T, LocationError> {
        return SignalProducer(signal: delegateObject.didFail)
            .map { $0 as! NSError }
            .flatMap (.latest) { (error: NSError) -> SignalProducer<T,LocationError> in
                return SignalProducer<T,LocationError>(error: LocationError.locationError(CLError(_nsError: error).code))
        }
    }

    static fileprivate func locationSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLLocation, LocationError> {
        return SignalProducer(signal: delegateObject.didUpdateLocations).promoteErrors(LocationError).map { $0.last! }
    }

    static fileprivate func headingSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLHeading, LocationError> {
        return SignalProducer(signal: delegateObject.didUpdateHeading).promoteErrors(LocationError)
    }

    static fileprivate func visitSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLVisit, LocationError> {
        return SignalProducer(signal: delegateObject.didVisit).promoteErrors(LocationError)
    }

    static fileprivate func regionSignal(_ delegateObject: ReactiveLocationManagerDelegate, regionState: RegionState) -> SignalProducer<RegionState, LocationError> {

        let signal: SignalProducer<RegionState, NoError>
        switch regionState {
        case .enter:
            signal = SignalProducer(signal: delegateObject.didEnterRegion).map { .enter($0) }
        case .exit:
            signal = SignalProducer(signal: delegateObject.didExitRegion).map { .exit($0) }
        }

        return signal.promoteErrors(LocationError)
    }

    static fileprivate func locationManagerFactory() -> CLLocationManager {
        let cl = CLLocationManager()
        let delegate = ReactiveLocationManagerDelegate()
        cl.delegate = delegate
        cl.delegateObject = delegate
        cl.desiredAccuracy = kCLLocationAccuracyBest
        return cl
    }

    static fileprivate func merge<T, E>(_ signals: [SignalProducer<T, E>]) -> SignalProducer<T, E> {
        let producers = SignalProducer<SignalProducer<T, E>, E>(values: signals)
        return producers.flatten(.merge)
    }
}
