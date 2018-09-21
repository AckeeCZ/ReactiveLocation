import CoreLocation
import ReactiveSwift

extension ReactiveLocationService {
    func locationProducer(timeout: Int = 1, _ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation?, LocationError> {
        return self.timeout(timeout, with: locationProducer(managerFactory))
    }
    
    func singleLocationProducer(timeout: Int = 1, _ managerFactory: LocationManagerConfigureBlock? = nil) -> SignalProducer<CLLocation?, LocationError> {
        return self.timeout(timeout, with: singleLocationProducer(managerFactory))
    }
    
    private func timeout(_ timeout: Int, with locationProducer: SignalProducer<CLLocation, LocationError>) -> SignalProducer<CLLocation?, LocationError> {
        let deadline = SignalProducer.timer(interval: .seconds(timeout), on: QueueScheduler.main).promoteError(LocationError.self).map { _ -> CLLocation? in return nil }.take(first: 1)
        return SignalProducer.merge(deadline, locationProducer.map { Optional($0) })
    }
}
