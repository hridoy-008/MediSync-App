# Required fonts (bundled — TRD §7, Design §3.2)

`pubspec.yaml` declares these font files. Add them here before the first build
(they are binaries and can't be checked in by the generator):

## NotoSansBengali (Bangla — correct conjunct rendering)
Download from Google Fonts (https://fonts.google.com/noto/specimen/Noto+Sans+Bengali):
- NotoSansBengali-Regular.ttf
- NotoSansBengali-Medium.ttf
- NotoSansBengali-SemiBold.ttf
- NotoSansBengali-Bold.ttf

## Inter (English)
Download from https://fonts.google.com/specimen/Inter :
- Inter-Regular.ttf
- Inter-Medium.ttf
- Inter-SemiBold.ttf
- Inter-Bold.ttf

> Until you add these, either drop the `fonts:` block from `pubspec.yaml` or the
> build will fail on missing assets. The UI still works with system fonts, but
> Bangla typography quality depends on NotoSansBengali.
