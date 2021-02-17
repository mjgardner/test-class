# Source code of Test::Class Perl module

For documentation see [Test::Class](https://metacpan.org/pod/Test::Class) on MetaCPAN.

## Release process

* Update VERSION number in every .pm file in lib/
* Update the Changes file.

```
perl Makefile.PL
make
make test
                     (TODO RELEASE_TESTING=1 prove xt/ )
make dist
```

```
git tags -a x.xx -m x.xx
git push --tags
```

