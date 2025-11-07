# ilmplanner

A new Flutter project.

## Configuration initiale

Avant d'ouvrir le projet dans Xcode ou de compiler, exécutez les commandes suivantes :

```bash
# 1. Installer les dépendances Flutter
flutter pub get

# 2. Installer les dépendances CocoaPods pour iOS
cd ios
pod install
cd ..

# 3. (Optionnel) Pour macOS, installer les dépendances
cd macos
pod install
cd ..
```

**Important** : Ces étapes sont nécessaires pour générer les fichiers de configuration requis par Xcode. Sans cela, vous rencontrerez l'erreur "unable to initiate PIF transfer session".

Pour plus de détails sur le dépannage, consultez [TROUBLESHOOTING.md](TROUBLESHOOTING.md).





### Pour deployer une nouvelle version sur IOS 


flutter clean 

flutter build ios --release --build-name=2.0.0 --build-number=1

Puis ouvre le projet dans Xcode (ios/Runner.xcworkspace) et fais :

Product > Archive → puis Upload to App Store Connect


### Pour deployer une nouvelle version sur Android

flutter clean
flutter pub get
flutter build appbundle --release


flutter clean

flutter build appbundle --release \
  --build-name=2.0.4 \
  --build-number=12