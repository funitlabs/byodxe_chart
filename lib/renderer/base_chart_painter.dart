import 'dart:math';
import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:bydoxe_chart/utils/date_format_util.dart';
import '../chart_style.dart' show ChartStyle;
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart';
import 'base_dimension.dart';
export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

/// BaseChartPainter
abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity>? datas; // data of chart
  MainState mainState;

  Set<SecondaryState> secondaryStateLi;

  bool volHidden;
  bool isTapShowInfoDialog;
  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;

  /// Rectangle box of main chart
  late Rect mMainRect;

  /// Rectangle box of the vol chart
  Rect? mVolRect;

  /// Secondary list support
  List<RenderRect> mSecondaryRectList = [];
  late double mDisplayHeight, mWidth;
  // padding
  double mTopPadding = 30.0, mBottomPadding = 20.0, mChildPadding = 12.0;
  // grid: rows - columns
  int mGridRows = 4, mGridColumns = 4;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive, mVolMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; // the data occupies the total length of the screen
  final ChartStyle chartStyle;
  late double mPointWidth;
  // format time
  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
  double xFrontPadding;

  /// base dimension
  final BaseDimension baseDimension;

  /// constructor BaseChartPainter
  ///
  BaseChartPainter(
    this.chartStyle, {
    this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.xFrontPadding,
    required this.baseDimension,
    this.isOnTap = false,
    this.mainState = MainState.MA,
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryStateLi = const <SecondaryState>{},
    this.isLine = false,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = this.chartStyle.pointWidth;
    mTopPadding = this.chartStyle.topPadding;
    mBottomPadding = this.chartStyle.bottomPadding;
    mChildPadding = this.chartStyle.childPadding;
    mGridRows = this.chartStyle.gridRows;
    mGridColumns = this.chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  /// init format time
  void initFormats() {
    if (this.chartStyle.dateTimeFormat != null) {
      mFormats = this.chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
      return;
    }

    int firstTime = datas!.first.time ?? 0;
    int secondTime = datas![1].time ?? 0;
    int time = secondTime - firstTime;
    time ~/= 1000;
    // monthly line
    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '-', mm];
    } else if (time >= 24 * 60 * 60) {
      // daily line
      mFormats = [yy, '-', mm, '-', dd];
    } else {
      // hour line
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
    }
  }

  /// paint chart
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas!.isNotEmpty) {
      drawChart(canvas, size);
      drawVerticalText(canvas);
      drawDate(canvas, size);

      drawText(canvas, datas!.last, 5);
      drawMaxAndMin(canvas);
      drawNowPrice(canvas);

      if (isLongPress == true || (isTapShowInfoDialog && isOnTap)) {
        drawCrossLineText(canvas, size);
      }
    }
    canvas.restore();
  }

  /// init chart renderer
  void initChartRenderer();

  /// draw the background of chart
  void drawBg(Canvas canvas, Size size);

  /// draw the grid of chart
  void drawGrid(canvas);

  /// draw chart
  void drawChart(Canvas canvas, Size size);

  /// draw vertical text
  void drawVerticalText(canvas);

  /// draw date
  void drawDate(Canvas canvas, Size size);

  /// draw text
  void drawText(Canvas canvas, KLineEntity data, double x);

  /// draw maximum and minimum values
  void drawMaxAndMin(Canvas canvas);

  /// draw the current price
  void drawNowPrice(Canvas canvas);

  /// draw cross line
  void drawCrossLine(Canvas canvas, Size size);

  /// draw text of the cross line
  void drawCrossLineText(Canvas canvas, Size size);

  /// init the rectangle box to draw chart
  void initRect(Size size) {
    // 1. 메인 차트 영역 계산
    double mainHeight = mDisplayHeight;
    // VOL 영역 분리 제거
    mainHeight -= (baseDimension.mSecondaryHeight * (secondaryStateLi.length));

    // 메인 영역은 항상 최상단에 위치
    mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight);

    // 2. 보조지표 영역 계산 (VOL 포함)
    mSecondaryRectList.clear();
    double currentTop = mMainRect.bottom + mChildPadding + mBottomPadding;

    for (SecondaryState state in secondaryStateLi) {
      double secondaryHeight = baseDimension.mSecondaryHeight;
      Rect secondaryRect =
          Rect.fromLTRB(0, currentTop, mWidth, currentTop + secondaryHeight);
      mSecondaryRectList.add(RenderRect(secondaryRect));
      currentTop += secondaryHeight + mChildPadding;
    }
  }

  /// calculate values
  calculateValue() {
    if (datas == null || datas!.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));

    // MACD, KDJ, RSI, WR, CCI, VOL 전체 범위 계산용 변수
    double macdMax = double.negativeInfinity, macdMin = double.infinity;
    double kdjMax = double.negativeInfinity, kdjMin = double.infinity;
    double rsiMax = double.negativeInfinity, rsiMin = double.infinity;
    double wrMax = double.negativeInfinity, wrMin = double.infinity;
    double cciMax = double.negativeInfinity, cciMin = double.infinity;
    double volMax = double.negativeInfinity, volMin = double.infinity;
    int macdIdx = secondaryStateLi.toList().indexOf(SecondaryState.MACD);
    int kdjIdx = secondaryStateLi.toList().indexOf(SecondaryState.KDJ);
    int rsiIdx = secondaryStateLi.toList().indexOf(SecondaryState.RSI);
    int wrIdx = secondaryStateLi.toList().indexOf(SecondaryState.WR);
    int cciIdx = secondaryStateLi.toList().indexOf(SecondaryState.CCI);
    int volIdx = secondaryStateLi.toList().indexOf(SecondaryState.VOL);

    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas![i];
      getMainMaxMinValue(item, i);
      for (int idx = 0; idx < mSecondaryRectList.length; ++idx) {
        if (macdIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.MACD) {
          if (item.macd != null && item.dif != null && item.dea != null) {
            macdMax = max(macdMax, max(item.macd!, max(item.dif!, item.dea!)));
            macdMin = min(macdMin, min(item.macd!, min(item.dif!, item.dea!)));
          }
        } else if (kdjIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.KDJ) {
          if (item.k != null && item.d != null && item.j != null) {
            kdjMax = max(kdjMax, max(item.k!, max(item.d!, item.j!)));
            kdjMin = min(kdjMin, min(item.k!, min(item.d!, item.j!)));
          }
        } else if (rsiIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.RSI) {
          if (item.rsi != null) {
            rsiMax = max(rsiMax, item.rsi!);
            rsiMin = min(rsiMin, item.rsi!);
          }
        } else if (wrIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.WR) {
          if (item.r != null) {
            wrMax = max(wrMax, item.r!);
            wrMin = min(wrMin, item.r!);
          }
        } else if (cciIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.CCI) {
          if (item.cci != null) {
            cciMax = max(cciMax, item.cci!);
            cciMin = min(cciMin, item.cci!);
          }
        } else if (volIdx == idx &&
            secondaryStateLi.elementAt(idx) == SecondaryState.VOL) {
          volMax = max(volMax,
              max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
          volMin = min(volMin,
              min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
        } else {
          getSecondaryMaxMinValue(idx, item);
        }
      }
    }

    // MACD, KDJ, RSI, WR, CCI, VOL 보조지표의 범위를 absMax로만 설정
    if (macdIdx >= 0 &&
        macdIdx < mSecondaryRectList.length &&
        macdMax > macdMin) {
      double absMax = max(macdMax.abs(), macdMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[macdIdx].mMaxValue = absMax;
      mSecondaryRectList[macdIdx].mMinValue = -absMax;
    }
    if (kdjIdx >= 0 && kdjIdx < mSecondaryRectList.length && kdjMax > kdjMin) {
      double absMax = max(kdjMax.abs(), kdjMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[kdjIdx].mMaxValue = absMax;
      mSecondaryRectList[kdjIdx].mMinValue = -absMax;
    }
    if (rsiIdx >= 0 && rsiIdx < mSecondaryRectList.length && rsiMax > rsiMin) {
      double absMax = max(rsiMax.abs(), rsiMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[rsiIdx].mMaxValue = absMax;
      mSecondaryRectList[rsiIdx].mMinValue = -absMax;
    }
    if (wrIdx >= 0 && wrIdx < mSecondaryRectList.length && wrMax > wrMin) {
      double absMax = max(wrMax.abs(), wrMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[wrIdx].mMaxValue = absMax;
      mSecondaryRectList[wrIdx].mMinValue = -absMax;
    }
    if (cciIdx >= 0 && cciIdx < mSecondaryRectList.length && cciMax > cciMin) {
      double absMax = max(cciMax.abs(), cciMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[cciIdx].mMaxValue = absMax;
      mSecondaryRectList[cciIdx].mMinValue = -absMax;
    }
    if (volIdx >= 0 && volIdx < mSecondaryRectList.length && volMax > volMin) {
      double absMax = max(volMax.abs(), volMin.abs());
      if (absMax < 1.0) absMax = 1.0;
      mSecondaryRectList[volIdx].mMaxValue = absMax;
      mSecondaryRectList[volIdx].mMinValue = 0;
    }
  }

  /// compute maximum and minimum value
  void getMainMaxMinValue(KLineEntity item, int i) {
    double maxPrice, minPrice;
    if (mainState == MainState.MA) {
      maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.EMA) {
      maxPrice = max(item.high, _findMaxMA(item.emaValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.emaValueList ?? [0]));
    } else if (mainState == MainState.BOLL) {
      maxPrice = max(item.high, item.up ?? item.high);
      minPrice = min(item.low, item.dn ?? item.low);
    } else if (mainState == MainState.SAR) {
      maxPrice = max(item.high, item.sar ?? item.high);
      minPrice = min(item.low, item.sar ?? item.low);
    } else if (mainState == MainState.AVL) {
      maxPrice = max(item.high, item.avl ?? item.high);
      minPrice = min(item.low, item.avl ?? item.low);
    } else {
      maxPrice = item.high;
      minPrice = item.low;
    }

    // NaN과 Infinite 값 처리
    if (maxPrice.isNaN || maxPrice.isInfinite) maxPrice = item.high;
    if (minPrice.isNaN || minPrice.isInfinite) minPrice = item.low;

    // 최대/최소값이 0 이하인 경우 처리
    if (minPrice <= 0) {
      double range = maxPrice - minPrice;
      minPrice = range * 0.1; // 최소값을 범위의 10%로 설정
    }

    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  // find maximum of the MA
  double _findMaxMA(List<double> a) {
    double result = double.minPositive;
    for (double i in a) {
      result = max(result, i);
    }
    return result;
  }

  // find minimum of the MA
  double _findMinMA(List<double> a) {
    double result = double.maxFinite;
    for (double i in a) {
      result = min(result, i == 0 ? double.maxFinite : i);
    }
    return result;
  }

  // compute maximum and minimum of secondary value
  getSecondaryMaxMinValue(int index, KLineEntity item) {
    if (index >= mSecondaryRectList.length) return;

    SecondaryState secondaryState = secondaryStateLi.elementAt(index);
    switch (secondaryState) {
      case SecondaryState.VOL:
        // VOL은 VolRenderer에서 처리되므로 여기서는 아무것도 하지 않음
        break;
      // MACD
      case SecondaryState.MACD:
        // MACD는 calculateValue에서 전체 범위로 처리
        break;
      // KDJ
      case SecondaryState.KDJ:
        if (item.k != null && item.d != null && item.j != null) {
          double maxValue = max(item.k!, max(item.d!, item.j!));
          double minValue = min(item.k!, min(item.d!, item.j!));
          if (!maxValue.isNaN &&
              !minValue.isNaN &&
              !maxValue.isInfinite &&
              !minValue.isInfinite) {
            // KDJ는 0-100 범위로 설정
            mSecondaryRectList[index].mMaxValue = 100;
            mSecondaryRectList[index].mMinValue = 0;
          }
        }
        break;
      // RSI
      case SecondaryState.RSI:
        if (item.rsi != null && !item.rsi!.isNaN && !item.rsi!.isInfinite) {
          // RSI는 0-100 범위로 설정
          mSecondaryRectList[index].mMaxValue = 100;
          mSecondaryRectList[index].mMinValue = 0;
        }
        break;
      // WR
      case SecondaryState.WR:
        // WR은 -100-0 범위로 설정
        mSecondaryRectList[index].mMaxValue = 0;
        mSecondaryRectList[index].mMinValue = -100;
        break;
      // CCI
      case SecondaryState.CCI:
        if (item.cci != null && !item.cci!.isNaN && !item.cci!.isInfinite) {
          // CCI는 -100-100 범위로 설정
          double absValue = item.cci!.abs();
          mSecondaryRectList[index].mMaxValue = max(100, absValue).toDouble();
          mSecondaryRectList[index].mMinValue = -max(100, absValue).toDouble();
        }
        break;
    }
  }

  // translate x
  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  /// Using binary search for the index of the current value
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  /// Get x coordinate based on index
  /// + mPointWidth / 2 to prevent the first and last K-line from displaying incorrectly
  /// @param position index value
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KLineEntity getItem(int position) {
    return datas![position];
    // if (datas != null) {
    //   return datas[position];
    // } else {
    //   return null;
    // }
  }

  /// scrollX convert to TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  /// get the minimum value of translation
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding;
    return x >= 0 ? 0.0 : x;
  }

  /// calculate the value of x after long pressing and convert to [index]
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  /// translateX is converted to X in view
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  /// define text style
  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
  }
}

/// Render Rectangle
class RenderRect {
  Rect mRect;
  double mMaxValue = double.negativeInfinity;
  double mMinValue = double.infinity;

  RenderRect(this.mRect);
}
