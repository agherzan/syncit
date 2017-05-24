# syncit

This small tool provides the ability to sync files or directories while ensuring durability.

It supports:

* sync to disk a file or a directory while making sure the parent directory is fsync'ed too
* sync to disk all the buffered modifications
* sync to disk the filesystem on which a specific file resides

## Install

```
make
make install
```

## How to use

When ran without file argument it will behave as a normal [sync](https://linux.die.net/man/8/sync).
When a file argument is provided the tool will fsync the file (which can be a directory too) and the parent directory to ensure durability of data.
When `-f` option is used, it will sync the entire filesystem the specified file resides on.

Check help:

```
syncit --help
```

## Contributions
Want to contribute? Great! Throw pull requests at us.
