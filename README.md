# ilmplanner

A new Flutter project.





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