# Slator CLI

<br>
<aside>
❗️ This is currently the bare minimum version which is working for me. Right now this will also propbably not work on Windows.
</aside>

<br>
<br>

## What it does and how it works

The cli tool searches for strings with a ‘.tr’ extension. For example this might look like this:

```dart
var translation = 'Apple'.tr;
```

This is inspired by the [get](https://pub.dev/packages/get) package translation approach, but you don’t have to use that package. You can implement your own translation logic when using this tool. 

In the most basic use case, the cli just generates a file at `locale/translations/base_translations/<language_code>.dart`. Where the language code is ‘de’ by default, but you can provide any you need. The file contents look like this:

```dart
final Map<String, String> en {
	//  main.dart
	'Apple': 'Apple',
}
```

You can then use that map in your string extension, to get the translations.

Furthermore, you can pass language codes to the cli for which languages the app should be able to support. The cli generates all necessary files for that at `locale/translations/<language_code>.dart`. 
Let’s say you provided the language code ‘de’ for german, so this file should generate:

```dart
final Map<String, String> de = {
	//  main.dart
	'Apple': '--missing translation--',
};
```

If you want to, you can provide a DeepL Auth Key so the cli generates all the translations for you.
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
$ dart pub global activate slator
```

**Or add it to your dev_dependencies in your project:**

```yaml
dev_dependencies:
  slator: any
```

## How To Use

**The most basic way is to run the command:**

```shell
$ slator
```

The default language is assumed to be german right now.
**The default language can be easily set to a different language with the following command:**

```shell
$ slator --default-language en
```

By default it uses the DeepL API to translate the missing strings and asks you, to enter your DeepL Auth Key. If you just leave it empty, the DeepL API will not work and it returns you a “missing translation” string.

**The** r**ecommended way if you don’t want to use the API:**

```shell
$ slator --no-use-deepl
```

**You can pass in all the language codes for the languages your app should support:**

```shell
$ slator --language-codes en,es,ru
```

**A full example could look like this:**

```shell
$ slator --default-language en --no-use-deepl --language-codes en,es,ru
```

## Updating or Deleting your DeepL Auth Key

**You can update your DeepL Auth Key:**

```bash
$ slator --update-deepl-key
```

**Or delete it:**

```bash
$ slator --delete-deepl-key
```