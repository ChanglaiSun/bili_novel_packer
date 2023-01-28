import 'package:archive/archive.dart';
import 'package:bili_novel_packer/media_type.dart';

import 'bili_novel_model.dart';

Chapter? getPrevChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 1) return null;
  return chapters[pos - 1];
}

Chapter? getNextChapter(Catalog catalog, Chapter chapter) {
  List<Chapter> chapters = catalog.volumes
      .expand(
        (volume) => volume.chapters,
      )
      .toList();
  int pos = chapters.indexOf(chapter);
  if (pos < 0 || pos > chapters.length - 1) return null;
  return chapters[pos + 1];
}

class ImageInfo {
  int width;
  int height;
  String mimeType;

  ImageInfo(this.width, this.height, this.mimeType);

  double get ratio => width / height;

  @override
  String toString() {
    return "ImageInfo(width = $width, height = $height, ratio = $ratio, mimeType = $mimeType)";
  }
}

ImageInfo? getImageInfo(InputStreamBase isb, [String? src]) {
  int width;
  int height;
  String mimeType;
  int c1 = isb.readByte();
  int c2 = isb.readByte();
  int c3 = isb.readByte();
  // GIF
  if (c1 == 0x47 && c2 == 0x49 && c3 == 0x46) {
    isb.skip(3);
    width = isb.readUint16();
    height = isb.readUint16();
    mimeType = gif;
    return ImageInfo(width, height, mimeType);
  }
  // JPG
  if (c1 == 0xFF && c2 == 0xD8) {
    while (c3 == 255) {
      int marker = isb.readByte();
      int len = _readInt(isb, 2, true);
      if (marker == 192 || marker == 193 || marker == 194) {
        isb.skip(1);
        height = _readInt(isb, 2, true);
        width = _readInt(isb, 2, true);
        mimeType = jpeg;
        return ImageInfo(width, height, mimeType);
      }
      isb.skip(len - 2);
      c3 = isb.readByte();
    }
  }
  // PNG
  if (c1 == 137 && c2 == 80 && c3 == 78) {
    isb.skip(15);
    width = _readInt(isb, 2, true);
    isb.skip(2);
    height = _readInt(isb, 2, true);
    mimeType = png;
    return ImageInfo(width, height, mimeType);
  }
  // BMP
  if (c1 == 66 && c2 == 77) {
    isb.skip(15);
    width = _readInt(isb, 2, false);
    isb.skip(2);
    height = _readInt(isb, 2, false);
    mimeType = bmp;
    return ImageInfo(width, height, mimeType);
  }
  // WEBP
  if (c1 == 0x52 && c2 == 0x49 && c3 == 0x46) {
    var bytes = isb.readBytes(27).toUint8List();
    width = (bytes[24] & 0xFF) << 8 | (bytes[23] & 0xFF);
    height = (bytes[26] & 0xFF) << 8 | (bytes[25] & 0xFF);
    mimeType = webp;
    return ImageInfo(width, height, mimeType);
  }
  return null;
  // throw "Unsupported image type $src";
}

int _readInt(InputStreamBase isb, int count, bool bigEndian) {
  int ret = 0;
  int sv = bigEndian ? ((count - 1) * 8) : 0;
  int cnt = bigEndian ? -8 : 8;
  for (int i = 0; i < count; i++) {
    ret |= isb.readByte() << sv;
    sv += cnt;
  }
  return ret;
}
