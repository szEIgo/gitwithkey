in ur zshrc, bashrc or fishrc file, add a function like this

```
gitwithkey() {
   ~/scripts/gitwithkey.sh "$@"
}

```

And now you should be able to execute git commands like this:


```
gitwithkey clone git@github.com:szEIgo/gitwithkey.git
gitwithkey pull
gitwithkey push
etc etc.
```
