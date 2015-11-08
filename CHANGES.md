Unreleased

1. remove large parsing code, replace with stream-search-helper use
2. remove tests for escaping inner braces, can only escape first of two braces
3. add file streaming tests to see how it's all handled
4. alter how escapes are input to the tests to more match how it should work based on file streaming tests
5. step up major version (again) because these change how kevas works

2.0.2 - Released 2015/09/21

1. added its name to its keywords because it wasn't showing up in npmjs.com search

2.0.1 - Released 2015/09/14

1. corrected example section for new API
2. added new section about listeners
3. added new section about instance creation

2.0.0 - Released 2015/09/13

1. onkey listeners executed via async.waterfall to allow later listeners to override value contributions of earlier listeners, and maintain ability for a listener to do async work before pushing content.

1.1.0 - [Unreleased]

1. optional async operations in onkey events via `done` callback

1.0.0 - Released 2015/09/10
