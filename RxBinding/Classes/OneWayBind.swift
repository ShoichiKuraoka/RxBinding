//
//  OneWayBind.swift
//  RxBinding
//
//  Created by Meng Li on 03/30/2019.
//  Copyright (c) 2019 MuShare. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import RxSwift
import RxCocoa

infix operator ~> : DefaultPrecedence

// Bind to the observer, the relay or the binder.
extension ObservableType {
    
    public static func ~> <O>(observable: Self, observer: O) -> Disposable where O: ObserverType, O.E == Self.E {
        return observable.bind(to: observer)
    }
    
    public static func ~> <O>(observable: Self, observer: O) -> Disposable where O : ObserverType, O.E == Self.E?  {
        return observable.bind(to: observer)
    }
    
    public static func ~> (observable: Self, relay: PublishRelay<Self.E>) -> Disposable {
        return observable.bind(to: relay)
    }
    
    public static func ~> (observable: Self, relay: PublishRelay<Self.E?>) -> Disposable {
        return observable.bind(to: relay)
    }
    
    public static func ~> (observable: Self, relay: BehaviorRelay<Self.E>) -> Disposable {
        return observable.bind(to: relay)
    }
    
    public static func ~> (observable: Self, relay: BehaviorRelay<Self.E?>) -> Disposable {
        return observable.bind(to: relay)
    }
    
    public static func ~> <R>(observable: Self, binder: (Self) -> R) -> R {
        return observable.bind(to: binder)
    }
    
    public static func ~> (observable: Self, binder: (Self) -> Disposable) -> Disposable {
        return observable.bind(to: binder)
    }
    
}

// Bind to the array of observer, relay or binder.
extension ObservableType {
    
    public static func ~> <O>(observable: Self, observers: [O]) -> [Disposable] where O: ObserverType, O.E == Self.E {
        return observers.map { observable.bind(to: $0) }
    }
    
    public static func ~> <O>(observable: Self, observers: [O]) -> [Disposable] where O : ObserverType, O.E == Self.E?  {
        return observers.map { observable.bind(to: $0) }
    }
    
    public static func ~> (observable: Self, relays: [PublishRelay<Self.E>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0) }
    }
    
    public static func ~> (observable: Self, relays: [PublishRelay<Self.E?>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0) }
    }
    
    public static func ~> (observable: Self, relays: [BehaviorRelay<Self.E>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0) }
    }
    
    public static func ~> (observable: Self, relays: [BehaviorRelay<Self.E?>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0) }
    }
    
    public static func ~> <R>(observable: Self, binders: [(Self) -> R]) -> [R] {
        return binders.map { observable.bind(to: $0) }
    }
    
}

infix operator ~~> : DefaultPrecedence

fileprivate struct LockDisposable {
    private let disposable: Disposable
    private weak var lifetimeInstance: AnyObject?
    private static var _instances: [LockDisposable] = []
    private static var _timerTarget: _TimerTarget? = nil
    
    static func retain(_ aDisposable: Disposable, untilReleaseOf aLifeTilmeInstance: Any) {
        _instances += [LockDisposable(disposable: aDisposable,
                                      lifetimeInstance: (aLifeTilmeInstance as AnyObject))]
        if _timerTarget == nil {
            let timerTarget = _TimerTarget()
            Timer.scheduledTimer(timeInterval: 0.1, target: timerTarget, selector: #selector(_TimerTarget.releaseIfNeeded), userInfo: nil, repeats: true)
            _timerTarget = timerTarget
        }
        // TODO: あとで消す
        // DebugLog ======
        print("LockDisposable count!!!!!: \(_instances.count)")
        // ===============
    }
    
    private class _TimerTarget {
        @objc func releaseIfNeeded() {
            guard LockDisposable._instances.contains(where: { $0.lifetimeInstance == nil }) else {
                return
            }
            LockDisposable._instances.filter({ $0.lifetimeInstance == nil }).forEach { $0.disposable.dispose() }
            LockDisposable._instances.removeAll(where: { $0.lifetimeInstance == nil })
        }
    }
}


extension Disposable {
    func retainUntilReleaseOf(_ observedInstance: Any) -> Disposable {
        LockDisposable.retain(self, untilReleaseOf: observedInstance)
        return self
    }
}

extension ObservableType {
    
    @discardableResult
    public static func ~~> <O>(observable: Self, observer: O) -> Disposable where O: ObserverType, O.E == Self.E {
        return observable.bind(to: observer).retainUntilReleaseOf(observable)
    }
    
    @discardableResult
    public static func ~~> <O>(observable: Self, observer: O) -> Disposable where O : ObserverType, O.E == Self.E?  {
        return observable.bind(to: observer).retainUntilReleaseOf(observable)
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relay: PublishRelay<Self.E>) -> Disposable {
        return observable.bind(to: relay).retainUntilReleaseOf(observable)
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relay: PublishRelay<Self.E?>) -> Disposable {
        return observable.bind(to: relay).retainUntilReleaseOf(observable)
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relay: BehaviorRelay<Self.E>) -> Disposable {
        return observable.bind(to: relay).retainUntilReleaseOf(observable)
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relay: BehaviorRelay<Self.E?>) -> Disposable {
        return observable.bind(to: relay).retainUntilReleaseOf(observable)
    }
    
    // TODO: まだ
    public static func ~~> <R>(observable: Self, binder: (Self) -> R) -> R {
        return observable.bind(to: binder)
    }
    
    @discardableResult
    public static func ~~> (observable: Self, binder: (Self) -> Disposable) -> Disposable {
        return observable.bind(to: binder).retainUntilReleaseOf(observable)
    }
    
}

extension ObservableType {
    
    @discardableResult
    public static func ~~> <O>(observable: Self, observers: [O]) -> [Disposable] where O: ObserverType, O.E == Self.E {
        return observers.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    @discardableResult
    public static func ~~> <O>(observable: Self, observers: [O]) -> [Disposable] where O : ObserverType, O.E == Self.E?  {
        return observers.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relays: [PublishRelay<Self.E>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relays: [PublishRelay<Self.E?>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relays: [BehaviorRelay<Self.E>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    @discardableResult
    public static func ~~> (observable: Self, relays: [BehaviorRelay<Self.E?>]) -> [Disposable] {
        return relays.map { observable.bind(to: $0).retainUntilReleaseOf(observable) }
    }
    
    // TODO: まだ
    public static func ~~> <R>(observable: Self, binders: [(Self) -> R]) -> [R] {
        return binders.map { observable.bind(to: $0) }
    }
}
