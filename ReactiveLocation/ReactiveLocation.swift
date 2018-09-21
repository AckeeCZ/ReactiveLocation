import CoreLocation
import ReactiveSwift
import Result

public typealias LocationManagerConfigureBlock = (CLLocationManager) -> Void

public enum LocationError: Error {
    case locationError(CLError.Code)
}

public enum RegionEvent {
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
    public init?(status: CLAuthorizationStatus) {
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
    func locationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError>
    func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLLocation, LocationError>
    func visitProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLVisit, LocationError>
    func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<RegionEvent, LocationError>
    func headingProducer(_ managerFactory: LocationManagerConfigureBlock?) -> SignalProducer<CLHeading, LocationError>
    
    var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> { get }
}

extension ReactiveLocationService {
    public func locationProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation, LocationError> {
        return locationProducer(managerFactory)
    }
    public func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation, LocationError> {
        return singleLocationProducer(managerFactory)
    }
    public func visitProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLVisit, LocationError> {
        return visitProducer(managerFactory)
    }
    public func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<RegionEvent, LocationError> {
        return regionProducer(region, managerFactory: managerFactory)
    }
    public func headingProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLHeading, LocationError> {
        return headingProducer(managerFactory)
    }
}

internal extension CLLocationManager {

    private struct AssociatedKeys {
        static var DescriptiveName = "ack_delegate"
    }

    internal var delegateObject: ReactiveLocationManagerDelegate? {
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

public class ReactiveLocation: ReactiveLocationService {

    private lazy var manager = LocationManagerConfigureBlock()
    
    public init() { }

    public func locationProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation, LocationError> {
        let manager = self.manager
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return SignalProducer.merge([errorSignal(delegateObject), locationSignal(delegateObject)])
            .on(started: {
                manager.startUpdatingLocation()
                }, terminated: {
                manager.stopUpdatingLocation()
        })
    }

    public func singleLocationProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation, LocationError> {
        let manager = self.manager
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }

        // -requestLocation guarantees callback called once
        return SignalProducer.merge([errorSignal(delegateObject), locationSignal(delegateObject)]).take(first: 1)
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

    public func headingProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLHeading, LocationError> {
        let manager = self.manager
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return SignalProducer.merge([errorSignal(delegateObject), headingSignal(delegateObject)])
            .on(started: {
                manager.startUpdatingHeading()
                }, terminated: {
                manager.stopUpdatingHeading()
        })
    }

    public func visitProducer(_ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLVisit, LocationError> {
        let manager = self.manager
        managerFactory?(manager)

        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        return SignalProducer.merge([errorSignal(delegateObject), visitSignal(delegateObject)])
            .on(started: {
                manager.startMonitoringVisits()
                }, terminated: {
                manager.stopMonitoringVisits()
        })
    }

    public func regionProducer(_ region: CLRegion, managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<RegionEvent, LocationError> {
        let manager = self.manager
        managerFactory?(manager)
        guard let delegateObject = manager.delegateObject else { return SignalProducer.empty }
        let enter = regionSignal(delegateObject, regionState: .exit(region))
        let error: SignalProducer<RegionEvent, LocationError> = errorSignal(delegateObject)
        let exit = regionSignal(delegateObject, regionState: .enter(region))
        return SignalProducer.merge([enter, exit, error])
            .on(started: {
                manager.startMonitoring(for: region)
                }, terminated: {
                    manager.stopMonitoring(for: region)
        })
    }

    public lazy var authorizeAction: Action<LocationAuthorizationLevel, LocationAuthorizationLevel, LocationAuthorizationError> = Action { [unowned self] targetLevel in
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
        
        let cl = self.manager
        return SignalProducer<CLAuthorizationStatus, NoError> { sink, dis in
            
            sink.send(value: CLLocationManager.authorizationStatus())
            sink.sendCompleted()
            }
            .promoteError(LocationAuthorizationError.self)
            .flatMap(.latest) { status -> SignalProducer<LocationAuthorizationLevel, LocationAuthorizationError> in
                if case .notDetermined = status {
                    return SignalProducer(cl.delegateObject!.didChangeAuthorizationStatus)
                        .on(started: {
                            switch targetLevel {
                            case .always: cl.requestAlwaysAuthorization()
                            case .whenInUse: cl.requestWhenInUseAuthorization()
                            }
                            }, terminated: {
                                _ = cl // make sure location manager does not get deallocated before action terminates
                        })
                        .filter { $0 != .notDetermined }
                        .promoteError(LocationAuthorizationError.self)
                        .take(first: 1)
                        .flatMap(.latest, translateStatus)
                } else {
                    return translateStatus(status)
                }
        }
    }

    // MARK: Internal

    private func errorSignal<T>(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<T, LocationError> {
        return SignalProducer(delegateObject.didFail)
            .map { $0 as NSError }
            .flatMap (.latest) { (error: NSError) -> SignalProducer<T,LocationError> in
                return SignalProducer<T,LocationError>(error: LocationError.locationError(CLError(_nsError: error).code))
        }
    }

    private func locationSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLLocation, LocationError> {
        return SignalProducer(delegateObject.didUpdateLocations).promoteError(LocationError.self).map { $0.last! }
    }

    private func headingSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLHeading, LocationError> {
        return SignalProducer(delegateObject.didUpdateHeading).promoteError(LocationError.self)
    }

    private func visitSignal(_ delegateObject: ReactiveLocationManagerDelegate) -> SignalProducer<CLVisit, LocationError> {
        return SignalProducer(delegateObject.didVisit).promoteError(LocationError.self)
    }

    private func regionSignal(_ delegateObject: ReactiveLocationManagerDelegate, regionState: RegionEvent) -> SignalProducer<RegionEvent, LocationError> {

        let signal: SignalProducer<RegionEvent, NoError>
        switch regionState {
        case .enter:
            signal = SignalProducer(delegateObject.didEnterRegion).map { .enter($0) }
        case .exit:
            signal = SignalProducer(delegateObject.didExitRegion).map { .exit($0) }
        }

        return signal.promoteError(LocationError.self)
    }

    private func LocationManagerConfigureBlock() -> CLLocationManager {
        let cl = CLLocationManager()
        let delegate = ReactiveLocationManagerDelegate()
        cl.delegate = delegate
        cl.delegateObject = delegate
        cl.desiredAccuracy = kCLLocationAccuracyBest
        return cl
    }
}
