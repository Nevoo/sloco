# Translator CLI

<br>

<aside>
💡 A small CLI Tool to help you with an approach to solve some issues we had with localizations.
</aside>
<br>
<br>
<aside>
❗️ This is currently the bare minimum version which is working for me. Right now this will also propbably not work on Windows.
</aside>

<br>
<br>

| Commands | Description |
| --- | --- |
| -u, --[no-]use-deepl | Translate all texts via the DeepL API (defaults to on) |
| -d, --default-language=<de> |  Set your default project language (defaults to "de") |
| -c, --language-codes=<en,es,ru> | Provide the languages your project should support |

## Installation

**Either install it globally:**

```shell
$ dart pub global activate translator
```

**Or add it to your dev_dependencies in your project:**

```yaml
dev_dependencies:
  translator: any
```

## How To Use

**The most basic way is to run the command:**

```shell
$ translator
```

The default language is assumed to be german right now.
**The default language can be easily set to a different language with the following command:**

```shell
$ translator --default-language en
```

By default it uses the DeepL API to translate the missing strings and asks you, to enter your DeepL Auth Key. If you just leave it empty, the DeepL API will not work and it returns you a “missing translation” string.

**The** r**ecommended way if you don’t want to use the API:**

```shell
$ translator --no-use-deepl
```

**You can pass in all the language codes for the languages your app should support:**

```shell
$ translator --language-codes en,es,ru
```

**A full example could look like this:**

```shell
$ translator --default-language en --no-use-deepl --language-codes en,es,ru
```