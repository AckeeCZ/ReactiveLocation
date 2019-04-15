# Changelog

- please enter new entries in format 

```
- <description> (#<PR_number>, kudos to @<author>)
```

## master

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
