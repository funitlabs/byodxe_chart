import 'package:flutter/material.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';
import '../chart_indicator.dart';

enum VerticalTextAlignment { left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  double _contentPadding = 5.0;
  final MAIndicatorSettings maSettings;
  final EMAIndicatorSettings emaSettings;
  final BOLLIndicatorConfig? bollSettings;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;
  final SARIndicatorConfig? sarSettings;
  final AVLIndicatorConfig? avlSettings;

  MainRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      this.isLine,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      this.verticalTextAlignment,
      {required this.maSettings,
      required this.emaSettings,
      this.bollSettings,
      this.sarSettings,
      this.avlSettings})
      : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(
        children: _createMATextSpan(data),
      );
    } else if (state == MainState.EMA) {
      span = TextSpan(
        children: _createEMATextSpan(data),
      );
    } else if (state == MainState.BOLL) {
      final boll = bollSettings;
      span = TextSpan(
        children: [
          if (boll != null)
            TextSpan(
              text: 'BOLL(${boll.day}, ${boll.k}) ',
              style: getTextStyle(boll.upColor),
            ),
          if (boll != null && boll.showUp && data.up != 0)
            TextSpan(
                text: "UP:${format(data.up)} ",
                style: getTextStyle(boll.upColor)),
          if (boll != null && boll.showMb && data.mb != 0)
            TextSpan(
                text: "MB:${format(data.mb)} ",
                style: getTextStyle(boll.mbColor)),
          if (boll != null && boll.showDn && data.dn != 0)
            TextSpan(
                text: "DN:${format(data.dn)} ",
                style: getTextStyle(boll.dnColor)),
        ],
      );
    } else if (state == MainState.SAR) {
      if (data.sar != null && sarSettings != null)
        span = TextSpan(
          text:
              "SAR(${sarSettings!.start}, ${sarSettings!.maximum}): ${format(data.sar)} ",
          style: getTextStyle(sarSettings!.dotColor),
        );
    } else if (state == MainState.AVL) {
      if (data.avl == null) {
        // ignore: avoid_print
        print('[AVL] drawText: avl 값이 null');
      }
      if (avlSettings == null) {
        // ignore: avoid_print
        print('[AVL] drawText: avlSettings가 null');
      }
      if (data.avl != null && avlSettings != null)
        span = TextSpan(
          text: "AVL: ${format(data.avl)} ",
          style: getTextStyle(avlSettings!.color),
        );
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        var item = TextSpan(
            text:
                "MA(${maSettings.dayList[i]}): ${format(data.maValueList![i])}    ",
            style: getTextStyle(this.chartColors.getMAColor(i)));
        result.add(item);
      }
    }
    return result;
  }

  List<InlineSpan> _createEMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    if (data.emaValueList == null) return result;
    for (int i = 0; i < data.emaValueList!.length; i++) {
      final v = data.emaValueList![i];
      if (v != 0) {
        result.add(TextSpan(
          text:
              "EMA(${emaSettings.dayList.length > i ? emaSettings.dayList[i] : '?'}): ${format(v)}    ",
          style: getTextStyle(emaSettings.emaList.length > i
              ? emaSettings.emaList[i].color
              : chartColors.kLineColor),
        ));
      }
    }
    return result;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.MA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.EMA) {
        drawEmaLine(lastPoint, curPoint, canvas, lastX, curX);
      } else if (state == MainState.BOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
      if (state == MainState.AVL) {
        drawAvlLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
    // SAR dot은 isLine 여부와 상관없이 항상 그린다
    if (state == MainState.SAR &&
        curPoint.sar != null &&
        curPoint.sarUpTrend != null) {
      final color = sarSettings?.dotColor ?? Colors.blue;
      canvas.drawCircle(
        Offset(curX, getY(curPoint.sar!)),
        3.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.lineFillColor,
        this.chartColors.lineFillInsideColor
      ],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    if (curPoint.maValueList == null || lastPoint.maValueList == null) return;
    for (int i = 0; i < curPoint.maValueList!.length; i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList![i] != 0) {
        drawLine(lastPoint.maValueList![i], curPoint.maValueList![i], canvas,
            lastX, curX, this.chartColors.getMAColor(i));
      }
    }
  }

  void drawEmaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    if (curPoint.emaValueList == null || lastPoint.emaValueList == null) return;
    for (int i = 0; i < curPoint.emaValueList!.length; i++) {
      final v1 = lastPoint.emaValueList![i];
      final v2 = curPoint.emaValueList![i];
      if (v1 != 0 && v2 != 0) {
        drawLine(
            v1,
            v2,
            canvas,
            lastX,
            curX,
            emaSettings.emaList.length > i
                ? emaSettings.emaList[i].color
                : chartColors.kLineColor);
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    final boll = bollSettings;
    if (boll != null) {
      if (boll.showUp &&
          lastPoint.up != null &&
          curPoint.up != null &&
          lastPoint.up != 0 &&
          curPoint.up != 0) {
        drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX, boll.upColor);
      }
      if (boll.showMb &&
          lastPoint.mb != null &&
          curPoint.mb != null &&
          lastPoint.mb != 0 &&
          curPoint.mb != 0) {
        drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX, boll.mbColor);
      }
      if (boll.showDn &&
          lastPoint.dn != null &&
          curPoint.dn != null &&
          lastPoint.dn != 0 &&
          curPoint.dn != 0) {
        drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX, boll.dnColor);
      }
    }
  }

  void drawAvlLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    if (lastPoint.avl == null || curPoint.avl == null) {
      // ignore: avoid_print
      print('[AVL] avl 값이 null: last=${lastPoint.avl}, cur=${curPoint.avl}');
      return;
    }
    final color = avlSettings?.color ?? Colors.orange;
    if (avlSettings == null) {
      // ignore: avoid_print
      print('[AVL] avlSettings가 null');
    }
    drawLine(lastPoint.avl, curPoint.avl, canvas, lastX, curX, color);
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        tp.paint(
            canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    if (y.isNaN || y.isInfinite) return chartRect.bottom;
    if (maxValue == minValue) return chartRect.bottom;

    // Y축 하단을 벗어나지 않도록 제한
    double yValue =
        (maxValue - y) * (chartRect.height / (maxValue - minValue)) +
            chartRect.top;
    return yValue.clamp(chartRect.top, chartRect.bottom);
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
