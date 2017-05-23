# syncit

This small tool provides the ability to sync files or directories while ensuring durability.

## Install

```
make
make install
```

## How to use

When ran without file argument it will behave as a normal [sync](https://linux.die.net/man/8/sync). When a file argument is provided the tool will fsync the file (which can be a directory too) and the parent directory to ensure durability of data.

Check help:

```
syncit --help
```

## Contributions
Want to contribute? Great! Throw pull requests at us.
