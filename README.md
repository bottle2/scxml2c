# scxml2c

Development is completely paralyzed until 2026.

There are several [Harel statechart](https://www.state-machine.com/doc/Harel87.pdf)
[interpreters](https://statecharts.dev/resources.html#tools--libraries).
This project wants to compile them into C code.

Competitors:

- [Embedded Coder](https://www.mathworks.com/products/embedded-coder.html)
- [uscxml](https://github.com/tklab-tud/uscxml) states that it can "transpile SCXML, e.g. onto ANSI-C and VHDL"
  - It provides no executables to download
  - I failed to compile it
  - Generated code isn't documented

## Installation and usage

To facilitate adoption, the tool is to comprise one single C89 source code,
so that either `$ make scxml2c` or `$ cc -o scxml{,.c}` is sufficient to acquire it.

It is envisioned for the tool to be integrated into a POSIX Makefile project:

```
.SUFFIXES:.c .h .scxml
.scxml.c:
	./scxml2c c $< > $@
.scxml.h:
	./scxml2c h $< > $@
```

Although the source code is to be delivered as a single file, the project actually emcompasses several files.
Thus, it is necessary "pack" the sources together in a "unity build" fashion.
This has not been done yet.
For reference, the library [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear/) employs a
[script](https://github.com/Immediate-Mode-UI/Nuklear/blob/master/src/build.py)
of their own for this purpose.

## License

This is tool is to be free software, while the generated code is to be unbounded by any licensing constraints, such that it is viable to used in both proprietary and non-proprietary software.

## Project structure

Development so far has been an educative opportunity to study XML and Unicode, to experiment generating code using M4, to combine several [Ragel](https://www.colm.net/open-source/ragel/) machines and to ponder about Ragel stack machines.

Because SCXML is XML, the program must decode both UTF-8 and UTF-16.
So input is first processed by a Ragel state machine that carries away the decodification.
The resulting individual Unicode scalar values (USV) are feeded to a Ragel stack machine that parses the XML itself.

Ragel lacks metaprogramming facilities, causing a lot of duplicate code.
To solve the maintenance burden, M4 has been studied to generate both C and Ragel code.
My approach consists of keeping a list of SCXML elements, their attributes and possible children elements in [`token.m4`](token.m4),
then this list is expanded several times to generate C enums, Ragel actions and Ragel machines.

Unaware that Ragel has a source inclusion facility through the `include` and `import` statements, I used the troff tool `soelim` to insert the generated code among the remainder of C/Ragel code where the request `.so` occurs.

[`Makefile`](Makefile) details and implements the entire pipeline.

## Entities

It is inviable to parse entities directly in the SCXML Ragel machine.
The solution is to add a Ragel machine between the Unicode machine and the SCXML machine.
This third machine, called Reference machine, will optionally detect XML entity references and expand them.

Because the tool is to perform entity expansion, it is subject to [Billion Laughs Attack](https://en.wikipedia.org/wiki/Billion_laughs_attack).
The tool will also postpone some entity expansion to the C preprocessor, when generating code, which will also be subject to the same attack.
It is possible that imposing C environmental limits may help mitigate the attack.
All things considered, the tool is not intended to process public-facing data.
Even if an online Web playground tool is provided, the tool is to be transformed to JavaScript/WebAssembly using [Emscripten](https://emscripten.org/) and run in the user's Web browser, so if the user inputs dangerous XML, only his computer is affected, and the server never process any data at all.
It doesn't make sense to provide this tools's functionality publicly as some Internet service; again, building the compiler should be trivial so that every build system have it locally.

Initially, the Reference machine will hand received USV directly over to the SCXML machine, including the `&` and `%`.
During this phase, the SCXML machine is responsible for filling two `rax` instances whenever `<!ENTITY ` occurs.
Accordingly, XML [states]() that at the time `<!ENTITY` is parsed, entity replacement mustn't happen anyway.

Eventually, the SCXML machine should be expanding entities with their corresponding replacement texts.
In order to do this, the SCXML machine will enable some global booleans telling the Reference machine to, when finding a `&` or `%`, to parse the subsequent USVs specially until a `;` is read, and the feed the SCXML machine with entire replacement texts, recursively.

Replacement text is tricky.
First of all, it could be a predefined entity: `&lt;`, `&gt;`, `&amp;`, `&apos;` and `&quot;`. The Reference machine would pass to the SCXML machine the values `<`, `>`, `&`, `'` and `"`.
Besides predefined entities, the user may define additional entities which contain characters imbued with meaning.
The solution is for the Reference machine to enable some boolean "bypass" parameter, so that the SCXML machine, through the `when` keyword, parse these characters without their meaning.
But it is a bit more complicated.
An entity can containing a number of XML elements with attributes; these need to be parsed correctly.

Speaking of entities containing tags and other XML elements, or having balanced parenthesis.
The XML ABNF for `<!ENTITY` declaration is very weak, because it allows all the problems while relying on verifications to ensure validity.
The SCXML machine must use a different production for entity declarations.
It must employ parallel states to detect several cases of validity, setting booleans when storing text in the `rax` instances.
These boolean informations can then be used to know when to set the bypass boolean or not.
We reuse other productions, such as the `element` production to validate this.

On the Reference machine acting on `;` and feeding replacement text.
All of this would happen inside an action.
However, a replacement text might contain more entities.
The SCXML, again, controls global booleans deciding whether to replace more or not.
So the Reference machine must feed itself with the replacement text.
Thus, we have a stack of pointers `*p`, `*pe` and `*eof`.
We possibly will have to use `fcall` and `fret`.
And further rules, where one entity must start and end in the same replacement text, never crossing boundaries: `EOF` errors can handle this.
We first feed until before some `&` or `%`, so the SCXML can react and change the global booleans.
So feeding replacement text must continue many times before ending.

So this is the overall gist.
Initially, we can get away from not replacing entities at all.
But to have a mature XML parser, it becomes crucial, at least to handle predefined entities.
It's be nice to have some test cases and a XML fuzzer setup until then.

## Recursive productions

The following productions are recursive:

- `element`
- `children`
- `conditionalSect`
  - Also `ignoreSectContents`

### Solution to `element` recursion

This one is the most important

### Solution to `children` recursion

Unsolved.

### Solution to `conditionalSect` and `ignoreSectContents` recursion

Unsolved.

## Datamodel

Initially, the `datamodel` must be `null`.

A `datamodel` specific for C code generation may be devised in the future, but no provisions are made.

## References

- [Extensible Markup Language (XML) 1.0 (Fifth Edition)](https://www.w3.org/TR/2008/REC-xml-20081126/)
- [State Chart XML (SCXML): State Machine Notation for Control Abstraction](https://www.w3.org/TR/2015/REC-scxml-20150901/)
- [The Unicode Standard: Version 16.0 – Core Specification](https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G7404)
