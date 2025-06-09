# Ramówka

Ramówka Radia Meteor

## Getting Started

Aplikacja ma służyć Radiu Meteor jako ramówka na stronę - punkt odniesienia dla tego co dzieje się aktualnie na antenie!

### Konfiguracja źródła danych

Dane ramówki pobierane są z publicznego arkusza Google Sheets. Id arkusza oraz nazwy zakładek dla tygodni A/B znajdują się w pliku `lib/data/services/google_sheet_service.dart` w mapie `sheetUrls`. Aby skorzystać z własnego arkusza należy podmienić tam adresy URL na własne.

### Uruchomienie projektu

Przed pierwszym uruchomieniem projektu należy pobrać zależności:

```bash
flutter pub get
```

Po instalacji paczek aplikację można uruchomić poleceniem `flutter run`.
