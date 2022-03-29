/// All CLI commands.
class Commands {
  const Commands._();

  /// Set the default language which is used in the project.
  static const defaultLanguage = 'default-language';

  /// Set a custom path to the project.
  ///
  /// The CLI defaults to your current relative path.
  /// @Unimplemented
  static const projectPath = 'project-path';

  /// Set a custom path to where your language files are generated.
  ///
  /// Defaults to `<projectPath>/locale/translations`
  /// @Unimplemented
  static const languageFilesPath = 'language-files-path';

  /// Set the language codes which the app should support
  static const languageCodes = 'language-codes';

  /// Use DeepL to translate your texts.
  ///
  /// You have to provide your own API Key to use this feature
  static const useDeepl = 'use-deepl';
}
