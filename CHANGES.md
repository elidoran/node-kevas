## 4.0.0 - Released 2017/05/24

1. rewrite, again. it's faster.
2. adapted test/lib for rewrite
3. added a bunch more tests
4. added tests for cli
5. added code coverage
6. added tests for 100% coverage
7. configure Travis CI to cache `node_modules`
8. made benchmark (not super complex tho). Compares `kevas` v3, an alternate implementation using `stating` nodes, `kevas` v4, and `streaming-format`. Haven't committed it yet because it's using a custom version of `benchmarked` to support `async/defer`. Benchmark shows kevas v4 is the fastest implementation of the four.


## 3.0.1 - Released 2017/01/10

1. fix value-store being built empty and not storing set key/value pairs from command line args
2. update deps
3. add 2017 to license

## 3.0.0 - Released 2016/11/03

(Changes 1-5 have been sitting on my computer for over a year, woops)

1. remove large parsing code, replace with stream-search-helper use
2. remove tests for escaping inner braces, can only escape first of two braces
3. add file streaming tests to see how it's all handled
4. alter how escapes are input to the tests to more match how it should work based on file streaming tests
5. swap async.waterfall for chain-builder
6. update deps
7. add `kevas` cli which transforms `stdin` and sends it to `stdout`. It gets the values via `nuc` and `value-store` loading files, using CLI args and environment variables.
8. revised the README content, added CLI section, and changed examples to JavaScript
9. created CoffeeScript version of README in `docs/`


## 2.0.2 - Released 2015/09/21

1. added its name to its keywords because it wasn't showing up in npmjs.com search

## 2.0.1 - Released 2015/09/14

1. corrected example section for new API
2. added new section about listeners
3. added new section about instance creation

## 2.0.0 - Released 2015/09/13

1. onkey listeners executed via async.waterfall to allow later listeners to override value contributions of earlier listeners, and maintain ability for a listener to do async work before pushing content.


## 1.1.0 - [Unreleased]

1. optional async operations in onkey events via `done` callback

## 1.0.0 - Released 2015/09/10
