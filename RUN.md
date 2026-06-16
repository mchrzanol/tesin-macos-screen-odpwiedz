# Jak odpalić TestAnswerBar

## Jedna komenda (zalecane)

```bash
pkill -9 -f swiftpm; pkill -9 -f swift-build; bash ./build-and-run.sh
```

`pkill` na początku ubija zawieszone procesy SwiftPM, które blokują katalog `.build`
(to przez nie wcześniej wisiało "Another instance of SwiftPM is already running").

## Jak coś się sypie totalnie (reset na czysto)

```bash
pkill -9 -f swiftpm; pkill -9 -f swift-build; pkill -9 -f TestAnswerBar; rm -rf .build TestAnswerBar.app; bash ./build-and-run.sh
```

## Zamknięcie aplikacji

`Ctrl+C` w terminalu, w którym działa.
