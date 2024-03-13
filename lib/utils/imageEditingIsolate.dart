import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:stack_blur/stack_blur.dart';

/// Die Darstellung eines Blur-Effekts auf einem Bild, zieht auf Apple-Devices
/// die Performance drastisch nach unten. Da wir aber nicht auf den Effekt
/// verzichten wollten, fanden wir eine Lösung dafür. Anstatt den herkömmlichen,
/// Flutter-nativen Weg zu wählen, bearbeiten wir eine Kopie des Bildes und
/// wenden den Blur direkt auf das Bild an. So muss das Device lediglich ein
/// geblurrtes Bild darstellen und nicht permanent eine Blur-Berechnung
/// durchführen. In einem Isolate wird das Bild dafür zerlegt, da das
/// der berechnungsintensivste Schritt dabei ist und anschließend weiter
/// verarbeitet.

img.Image blurImage(File imageFile) {
  final image = img.decodeImage(imageFile.readAsBytesSync())!;
  Uint32List rgbaPixels = image.data;

  stackBlurRgba(rgbaPixels, image.width, image.height, 100);

  return image;
}
