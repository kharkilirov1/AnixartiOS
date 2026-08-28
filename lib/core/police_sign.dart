import 'dart:convert';
import 'dart:math';

/// 1:1 port of com.swiftsoft.anixartd.utils.Police (Anixart 8.5.2).
/// The algorithm was verified against the production API.
class PoliceSign {
  /// MD5 of the APK signing certificate (extracted from CERT.RSA).
  static const String _certMd5Hex = '9aa5c7af74e8cd70c86f7f9587bde23d';
  static const String _packageName = 'com.swiftsoft.anixartd';
  /// Android 14; Police only uses the last digit of SDK_INT.
  static const int _sdkInt = 34;

  static const String _alnum =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static final Random _rnd = Random.secure();

  // Pools (verified against Police.smali)
  static List<int> _range(int a, int b) => List<int>.generate(b - a + 1, (i) => a + i);

  static final List<int> pool1 = [..._range(65, 70), ..._range(117, 122), ..._range(48, 50), 43, 33, 38, 60, 41];
  static final List<int> pool2 = [..._range(78, 90), ..._range(97, 109), ..._range(53, 57), 43, 33, 38, 60, 41];
  static final List<int> pool3 = [..._range(71, 76), ..._range(111, 116), ..._range(51, 52), 63, 94, 40, 46, 47];
  static final List<int> pool4 = [..._range(77, 82), ..._range(105, 110), ..._range(53, 54), 36, 92, 37, 125, 64];
  static final List<int> pool5 = [..._range(83, 90), ..._range(97, 104), ..._range(55, 57), 43, 93, 62, 123, 63];
  static final List<int> pool6 = [..._range(54, 57), 94, 62, 126, 47];
  static final List<int> pool7 = [..._range(49, 53), 37, 60, 38, 63];
  static final List<int> gI5One = [60, 123, 93, 35, 64];
  static final List<int> gI5Two = [37, 125, 91, 36, 94];

  static String make() {
    final strA = _randAlnum(4); // strD2
    final strA2 = _randAlnum(8); // strD
    final iH = _rnd.nextInt(9) + 1;

    final strD3 = _randChars(6, pool1);

    // Long.parseLong("1" + reverse(tsSeconds)) + 2112
    final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final head = BigInt.parse('1${_reverse(ts)}') + BigInt.parse('2112');
    var sb = head.toString().split('');
    final length = sb.length;
    if (length >= 1) {
      var i3 = 1, i4 = 0;
      while (true) {
        final pos = i3 + i4;
        sb.insert(pos, _randChars(1, pool2));
        i4++;
        if (i3 == length) break;
        i3++;
      }
    }
    final string2 = sb.join();

    final strD4 = _randChars(7, pool3);
    final strD5 = _randChars(4, pool4);
    final jLongValue = [99, 74, 49][_rnd.nextInt(3)] - 12;
    final strD6 = _randChars(7, pool5);
    final j2 = int.parse(_sdkInt.toString().substring(_sdkInt.toString().length - 1));
    final iH2 = _rnd.nextInt(18) + 10;

    final str4 = strD3 + string2 + strD4 + strD5 + jLongValue.toString() + strD6 + j2.toString() + iH2.toString();

    final s = iH2.toString();
    final i5 = int.parse(s.substring(0, 1));
    final i6 = int.parse(s.substring(s.length - 1));
    final i7 = i5 + i6;

    String str5;
    if (i5 == 1) {
      final payload = _caesar(_shiftDigits(str4, i7 - 1), i6);
      final b64 = base64.encode(utf8.encode(payload));
      str5 = b64 + i6.toString() + _randChars(2, pool7) + _randChars(1, gI5One);
    } else if (i5 == 2) {
      final b64 = base64.encode(utf8.encode(str4));
      str5 = _caesar(_shiftDigits(b64, i7), i6) + i6.toString() + _randChars(2, pool6) + _randChars(1, gI5Two);
    } else {
      return '';
    }

    final strI = _reverse(_certMd5Hex);
    final strD2 = strA; // dead branch always falls through to this
    final strD = strA2;

    final strE = _caesar(strI, _countDigits(strD2) + 1);
    final pkgE = _caesar(_packageName, _countDigits(strD) + 2);

    final combined = strD2 + str5 + strE + pkgE + strD;
    final b64f = base64.encode(utf8.encode(combined));
    return _shiftDigits(b64f, iH) + iH.toString() + _randAlnum(7);
  }

  /// AnixartApp/8.5.2-26032112 (Android %s; SDK %s; %s; %s %s; %s)
  static String userAgent() {
    return 'AnixartApp/8.5.2-26032112 (Android 14; SDK 34; arm64-v8a; Google Pixel 8; ru)';
  }

  static String _randAlnum(int n) =>
      List.generate(n, (_) => _alnum[_rnd.nextInt(_alnum.length)]).join();

  static String _randChars(int n, List<int> pool) => List.generate(
      n, (_) => String.fromCharCode(pool[_rnd.nextInt(pool.length)])).join();

  /// Police.g — shift ASCII decimal digits by -n, wrapping +10 below '0'.
  static String _shiftDigits(String s, int n) {
    final out = StringBuffer();
    for (final code in s.codeUnits) {
      if (code >= 48 && code <= 57) {
        var v = code - n;
        if (v < 48) v += 10;
        out.writeCharCode(v);
      } else {
        out.writeCharCode(code);
      }
    }
    return out.toString();
  }

  /// Police.e — Caesar shift on ASCII letters, shift % 26, wrap by 26.
  static String _caesar(String s, int shift) {
    final k = shift % 26;
    if (k == 0) return s;
    final out = StringBuffer();
    for (final code in s.codeUnits) {
      var c = code;
      if (c >= 0x41 && c < 0x5B) {
        c += k;
        if (c > 0x5A) c -= 26;
      } else if (c >= 0x61 && c < 0x7B) {
        c += k;
        if (c > 0x7A) c -= 26;
      }
      out.writeCharCode(c);
    }
    return out.toString();
  }

  static int _countDigits(String s) =>
      s.codeUnits.where((c) => c >= 48 && c <= 57).length;

  static String _reverse(String s) => String.fromCharCodes(s.codeUnits.reversed);
}
