import 'dart:math';

import '../entity/index.dart';

class DataUtil {
  static calculate(List<KLineEntity> dataList,
      [List<int> maDayList = const [5, 10, 20],
      int n = 20,
      k = 2,
      List<int> emaDayList = const [],
      double sarStart = 0.02,
      double sarMax = 0.2]) {
    calcMA(dataList, maDayList);
    calcEMA(dataList, emaDayList);
    calcBOLL(dataList, n, k);
    calcVolumeMA(dataList);
    calcKDJ(dataList);
    calcMACD(dataList);
    calcRSI(dataList);
    calcWR(dataList);
    calcCCI(dataList);
    calcSAR(dataList, sarStart, sarMax);
    calcAVL(dataList);
  }

  static calcMA(List<KLineEntity> dataList, List<int> maDayList) {
    List<double> ma = List<double>.filled(maDayList.length, 0);

    if (dataList.isNotEmpty) {
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        final closePrice = entity.close;
        entity.maValueList = List<double>.filled(maDayList.length, 0);

        for (int j = 0; j < maDayList.length; j++) {
          ma[j] += closePrice;
          if (i == maDayList[j] - 1) {
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else if (i >= maDayList[j]) {
            ma[j] -= dataList[i - maDayList[j]].close;
            entity.maValueList?[j] = ma[j] / maDayList[j];
          } else {
            entity.maValueList?[j] = 0;
          }
        }
      }
    }
  }

  static void calcEMA(List<KLineEntity> dataList, List<int> emaDayList) {
    if (emaDayList.isEmpty) return;
    if (dataList.isEmpty) return;
    for (int j = 0; j < emaDayList.length; j++) {
      double? lastEma;
      int day = emaDayList[j];
      for (int i = 0; i < dataList.length; i++) {
        KLineEntity entity = dataList[i];
        entity.emaValueList ??= List<double>.filled(emaDayList.length, 0);
        double close = entity.close;
        if (i == 0) {
          lastEma = close;
        } else {
          lastEma = (close - lastEma!) * (2 / (day + 1)) + lastEma;
        }
        entity.emaValueList![j] = lastEma;
      }
    }
  }

  static void calcBOLL(List<KLineEntity> dataList, int n, double k) {
    if (dataList.isEmpty) return;
    for (int i = 0; i < dataList.length; i++) {
      if (i + 1 >= n) {
        // n일간의 종가로 SMA, 표준편차 계산
        double sum = 0;
        for (int j = i - n + 1; j <= i; j++) {
          sum += dataList[j].close;
        }
        double sma = sum / n;
        // 표준편차 계산
        double sumSq = 0;
        for (int j = i - n + 1; j <= i; j++) {
          sumSq += (dataList[j].close - sma) * (dataList[j].close - sma);
        }
        double std = sqrt(sumSq / n);
        dataList[i].BOLLMA = sma;
        dataList[i].mb = sma;
        dataList[i].up = sma + k * std;
        dataList[i].dn = sma - k * std;
      } else {
        dataList[i].BOLLMA = null;
        dataList[i].mb = null;
        dataList[i].up = null;
        dataList[i].dn = null;
      }
    }
  }

  static void calcMACD(List<KLineEntity> dataList) {
    double ema12 = 0;
    double ema26 = 0;
    double dif = 0;
    double dea = 0;
    double macd = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final closePrice = entity.close;
      if (i == 0) {
        ema12 = closePrice;
        ema26 = closePrice;
      } else {
        // EMA（12） = 前一日EMA（12） X 11/13 + 今日收盘价 X 2/13
        ema12 = ema12 * 11 / 13 + closePrice * 2 / 13;
        // EMA（26） = 前一日EMA（26） X 25/27 + 今日收盘价 X 2/27
        ema26 = ema26 * 25 / 27 + closePrice * 2 / 27;
      }
      // DIF = EMA（12） - EMA（26） 。
      // 今日DEA = （前一日DEA X 8/10 + 今日DIF X 2/10）
      // 用（DIF-DEA）*2即为MACD柱状图。
      dif = ema12 - ema26;
      dea = dea * 8 / 10 + dif * 2 / 10;
      macd = (dif - dea) * 2;
      entity.dif = dif;
      entity.dea = dea;
      entity.macd = macd;
    }
  }

  static void calcVolumeMA(List<KLineEntity> dataList) {
    double volumeMa5 = 0;
    double volumeMa10 = 0;

    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entry = dataList[i];

      volumeMa5 += entry.vol;
      volumeMa10 += entry.vol;

      if (i == 4) {
        entry.MA5Volume = (volumeMa5 / 5);
      } else if (i > 4) {
        volumeMa5 -= dataList[i - 5].vol;
        entry.MA5Volume = volumeMa5 / 5;
      } else {
        entry.MA5Volume = 0;
      }

      if (i == 9) {
        entry.MA10Volume = volumeMa10 / 10;
      } else if (i > 9) {
        volumeMa10 -= dataList[i - 10].vol;
        entry.MA10Volume = volumeMa10 / 10;
      } else {
        entry.MA10Volume = 0;
      }
    }
  }

  static void calcRSI(List<KLineEntity> dataList) {
    double? rsi;
    double rsiABSEma = 0;
    double rsiMaxEma = 0;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      final double closePrice = entity.close;
      if (i == 0) {
        rsi = 0;
        rsiABSEma = 0;
        rsiMaxEma = 0;
      } else {
        double rMax = max(0, closePrice - dataList[i - 1].close.toDouble());
        double rAbs = (closePrice - dataList[i - 1].close.toDouble()).abs();

        rsiMaxEma = (rMax + (14 - 1) * rsiMaxEma) / 14;
        rsiABSEma = (rAbs + (14 - 1) * rsiABSEma) / 14;
        rsi = (rsiMaxEma / rsiABSEma) * 100;
      }
      if (i < 13) rsi = null;
      if (rsi != null && rsi.isNaN) rsi = null;
      entity.rsi = rsi;
    }
  }

  static void calcKDJ(List<KLineEntity> dataList) {
    var preK = 50.0;
    var preD = 50.0;
    final tmp = dataList.first;
    tmp.k = preK;
    tmp.d = preD;
    tmp.j = 50.0;
    for (int i = 1; i < dataList.length; i++) {
      final entity = dataList[i];
      final n = max(0, i - 8);
      var low = entity.low;
      var high = entity.high;
      for (int j = n; j < i; j++) {
        final t = dataList[j];
        if (t.low < low) {
          low = t.low;
        }
        if (t.high > high) {
          high = t.high;
        }
      }
      final cur = entity.close;
      var rsv = (cur - low) * 100.0 / (high - low);
      rsv = rsv.isNaN ? 0 : rsv;
      final k = (2 * preK + rsv) / 3.0;
      final d = (2 * preD + k) / 3.0;
      final j = 3 * k - 2 * d;
      preK = k;
      preD = d;
      entity.k = k;
      entity.d = d;
      entity.j = j;
    }
  }

  static void calcWR(List<KLineEntity> dataList) {
    double r;
    for (int i = 0; i < dataList.length; i++) {
      KLineEntity entity = dataList[i];
      int startIndex = i - 14;
      if (startIndex < 0) {
        startIndex = 0;
      }
      double max14 = double.minPositive;
      double min14 = double.maxFinite;
      for (int index = startIndex; index <= i; index++) {
        max14 = max(max14, dataList[index].high);
        min14 = min(min14, dataList[index].low);
      }
      if (i < 13) {
        entity.r = -10;
      } else {
        r = -100 * (max14 - dataList[i].close) / (max14 - min14);
        if (r.isNaN) {
          entity.r = null;
        } else {
          entity.r = r;
        }
      }
    }
  }

  static void calcCCI(List<KLineEntity> dataList) {
    final size = dataList.length;
    final count = 14;
    for (int i = 0; i < size; i++) {
      final kline = dataList[i];
      final tp = (kline.high + kline.low + kline.close) / 3;
      final start = max(0, i - count + 1);
      var amount = 0.0;
      var len = 0;
      for (int n = start; n <= i; n++) {
        amount += (dataList[n].high + dataList[n].low + dataList[n].close) / 3;
        len++;
      }
      final ma = amount / len;
      amount = 0.0;
      for (int n = start; n <= i; n++) {
        amount +=
            (ma - (dataList[n].high + dataList[n].low + dataList[n].close) / 3)
                .abs();
      }
      final md = amount / len;
      kline.cci = ((tp - ma) / 0.015 / md);
      if (kline.cci!.isNaN) {
        kline.cci = 0.0;
      }
    }
  }

  /// Parabolic SAR 계산
  static void calcSAR(
      List<KLineEntity> dataList, double start, double maximum) {
    if (dataList.isEmpty) return;
    double af = start;
    bool upTrend = true;
    double ep = dataList[0].high;
    dataList[0].sar = dataList[0].low;
    dataList[0].sarUpTrend = upTrend;

    for (int i = 1; i < dataList.length; i++) {
      final prev = dataList[i - 1];
      final cur = dataList[i];

      // 1. SAR 계산
      double sar = prev.sar! + af * (ep - prev.sar!);

      // 2. 추세별 SAR 값 보정 (이전 1~2개 캔들의 high/low와 비교)
      if (upTrend) {
        sar = min(sar, prev.low);
        if (i > 1) sar = min(sar, dataList[i - 2].low);
      } else {
        sar = max(sar, prev.high);
        if (i > 1) sar = max(sar, dataList[i - 2].high);
      }

      // 3. 추세 전환 체크
      bool switchTrend = false;
      if (upTrend) {
        if (cur.low < sar) {
          upTrend = false;
          sar = ep; // 전환 시 SAR은 직전 EP로 초기화
          af = start;
          ep = cur.low;
          switchTrend = true;
        }
      } else {
        if (cur.high > sar) {
          upTrend = true;
          sar = ep;
          af = start;
          ep = cur.high;
          switchTrend = true;
        }
      }

      // 4. EP, AF 갱신
      if (!switchTrend) {
        if (upTrend) {
          if (cur.high > ep) {
            ep = cur.high;
            af = min(af + start, maximum);
          }
        } else {
          if (cur.low < ep) {
            ep = cur.low;
            af = min(af + start, maximum);
          }
        }
      }

      cur.sar = sar;
      cur.sarUpTrend = upTrend;
    }
  }

  /// AVL(평균가격선) 계산
  static void calcAVL(List<KLineEntity> dataList) {
    for (final entity in dataList) {
      entity.avl = (entity.high + entity.low) / 2;
    }
    if (dataList.isNotEmpty) {
      // ignore: avoid_print
      print(
          '[AVL] calcAVL: first=${dataList.first.avl}, last=${dataList.last.avl}');
    }
  }
}
