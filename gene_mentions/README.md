
```
antlr4 -Dlanguage=Python3 Gm.g4
python3 -m unittest discover -s . -p GmTests.py
```

```
export CLASSPATH=".:"$(nix-store -qR $(which antlr4) | grep antlr)"/share/java/antlr-4.7.1-complete.jar:$CLASSPATH"
# or maybe one of these:
export CLASSPATH=".:"$(nix-store -qR $(which antlr4) | grep antlr)"/share/java/antlr-*-complete.jar:$CLASSPATH"
export CLASSPATH=".:"$(nix-store -qR $(which antlr4) | grep antlr)"/share/java/*.jar:$CLASSPATH"
```

```
```

Follow [these instructions](https://github.com/antlr/antlr4/blob/master/doc/getting-started.md).

```
mkdir metric
cd metric
wget https://raw.githubusercontent.com/antlr/grammars-v4/master/metric/metric.g4
antlr4 metric.g4
javac metric*.java
```

```
$ grun metric uom -tree
cm
^D
(uom (measure (prefix c) (unit (baseunit m))))
```

```
mkdir gm
cd gm
cat ../GMEntries.ebnf | \
  sed 's/::=/:/g' | \
  sed 's/^<.*>//g' | \
  sed "s/\(^[a-zA-Z]\)/;\1/g" | \
  awk '{gsub(/;/,"         ;\n")}1' | \
  awk 'NR==1,/[ ]+;/{sub(/[ ]+;/, "grammar gm;\nr : GMEntries ;")} 1' | \
  sed 's/#xA/\[\\n\]/g' > gm.g4
echo ';' >> gm.g4
antlr4 gm.g4; javac gm*.java
grun gm gmentries -tree ./input.txt
```
