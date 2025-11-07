# Guide de dépannage IlmPlanner

## Erreur : "unable to initiate PIF transfer session"

### Symptôme
Lors de l'ouverture du projet dans Xcode, vous recevez l'erreur :
```
error: Could not compute dependency graph: MsgHandlingError(message: "unable to initiate PIF transfer session (operation in progress?)")
```

### Cause
Cette erreur se produit lorsque les fichiers de configuration Flutter générés sont manquants. Xcode ne peut pas construire le graphe de dépendances sans ces fichiers :
- `ios/Flutter/Generated.xcconfig`
- `macos/Flutter/ephemeral/Flutter-Generated.xcconfig`
- Dépendances CocoaPods non installées

### Solution

#### Étape 1 : Générer les fichiers de configuration Flutter
```bash
flutter pub get
```

Cette commande crée les fichiers de configuration nécessaires et met à jour les dépendances.

#### Étape 2 : Installer les dépendances CocoaPods pour iOS
```bash
cd ios
pod install
cd ..
```

#### Étape 3 : (Optionnel) Installer les dépendances CocoaPods pour macOS
Si vous développez pour macOS :
```bash
cd macos
pod install
cd ..
```

#### Étape 4 : Ouvrir le projet dans Xcode
```bash
open ios/Runner.xcworkspace
```

**Important** : Toujours ouvrir le fichier `.xcworkspace`, pas le fichier `.xcodeproj`.

### Vérification
Après avoir suivi ces étapes, vérifiez que les fichiers suivants existent :
- `ios/Flutter/Generated.xcconfig`
- `ios/Pods/` (répertoire)
- `ios/.symlinks/` (répertoire)

## Autres erreurs courantes

### "No such module" lors de la compilation
**Solution** : Exécutez `pod install` dans le répertoire `ios/` puis nettoyez et recompilez dans Xcode.

### "Unable to boot simulator"
**Solution** : Redémarrez Xcode et/ou le simulateur iOS.

### Problèmes de dépendances pub
**Solution** :
```bash
flutter clean
flutter pub get
```

## Support
Pour plus d'assistance, consultez la [documentation Flutter](https://docs.flutter.dev/) ou créez une issue sur le dépôt.
