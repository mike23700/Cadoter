import 'package:flutter/widgets.dart';

import 'i18n_en.dart';

/// Traduction FR / EN. Le texte français sert de clé : tr('Se connecter') renvoie la version
/// anglaise (i18n_en.dart) quand l'anglais est choisi, sinon le texte tel quel.
class I18n {
  static String lang = 'fr';

  /// Reconstruit tous les écrans ouverts après un changement de langue.
  static void rebuildAll() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}

/// Texte traduit dans la langue courante (ou [lang]), avec remplacement des {variables}.
String tr(String fr, [Map<String, Object?> vars = const {}, String? lang]) {
  var s = (lang ?? I18n.lang) == 'en' ? (en[fr] ?? fr) : fr;
  vars.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Singulier / pluriel selon la langue (« 0 cadeau » en français, « 0 gifts » en anglais).
String trn(int n, String one, String many) => tr((I18n.lang == 'en' ? n == 1 : n <= 1) ? one : many, {'n': n});
