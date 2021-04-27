# Changelog

- please enter new entries in format to **master** section

```
- <description> (#<PR_number>, kudos to @<author>)
```

## master

- Fix getting location permissions (#30)
- Fix single location retrieve (#30)

## 4.0.1

- fix missing permission request for `singleLocation` (#29, kudos to @lukashromadnik)

## 4.0

- update ReactiveSwift to 6.1.0 (#26, kudos to @fortmarek)
- update ReactiveSwift to 6.0, ReactiveCocoa to 10.0, remove Result as native Result is used (#24, kudos to @olejnjak)

## 4.0 beta 2

- move location permission request out of _ReactiveLocation_ (#22, kudos to @olejnjak)
- add single location producer that returns `nil` if timeout occurs (#23, kudos to @olejnjak)

## 4.0 beta 1

- completely new version (#19, kudos to @olejnjak)
  - automatically asks for permissions
  - monitors observers and starts/stops updating location
  - fits better in dependency injection as it doesn't use static methods

## 3.2

- fix recursive calls when calling without parameters (#17, kudos to @olejnjak)
- migrate to Swift 5 & Xcode 10 (#18, kudos to @olejnjak)
