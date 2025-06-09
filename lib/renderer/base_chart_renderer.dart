import 'package:flutter/material.dart';
import '../utils/number_util.dart';

export '../chart_style.dart';

abstract class BaseChartRenderer<T> {
  double maxValue, minValue;
  late double scaleY;
  double topPadding;
  Rect chartRect;
  int fixedLength;
  Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0
    ..color = Colors.red;
  Paint gridPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 0.5
    ..color = Color(0xff4c5c74);
  bool skipPadding;

  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.fixedLength,
    required Color gridColor,
    this.skipPadding = false,
  }) {
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }

    if (maxValue.isNaN ||
        minValue.isNaN ||
        maxValue.isInfinite ||
        minValue.isInfinite) {
      maxValue = 100;
      minValue = 0;
    }

    if (!skipPadding) {
      double range = maxValue - minValue;
      double padding = range * 0.1;
      maxValue += padding;
      minValue -= padding;

      if (minValue < 0) {
        double totalRange = maxValue - minValue;
        maxValue = totalRange * 0.1;
        minValue = -totalRange * 0.9;
      }
    }

    scaleY = chartRect.height / (maxValue - minValue);
    gridPaint.color = gridColor;
    // print("maxValue=====" + maxValue.toString() + "====minValue===" + minValue.toString() + "==scaleY==" + scaleY.toString());
  }

  double getY(double y) {
    if (y.isNaN || y.isInfinite) return chartRect.bottom;
    if (maxValue == minValue) return chartRect.bottom;

    // 각 영역 내에서만 표시되도록 제한
    double yValue = (maxValue - y) * scaleY + chartRect.top;
    return yValue.clamp(chartRect.top + 10, chartRect.bottom - 10);
  }

  String format(double? n) {
    if (n == null || n.isNaN) {
      return "0.00";
    } else {
      return NumberUtil.format(n, format: NumberFormat.character);
    }
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);

  void drawText(Canvas canvas, T data, double x);

  void drawVerticalText(canvas, textStyle, int gridRows);

  void drawChart(T lastPoint, T curPoint, double lastX, double curX, Size size,
      Canvas canvas);

  void drawLine(double? lastPrice, double? curPrice, Canvas canvas,
      double lastX, double curX, Color color) {
    if (lastPrice == null ||
        curPrice == null ||
        lastPrice.isNaN ||
        curPrice.isNaN ||
        lastPrice.isInfinite ||
        curPrice.isInfinite) {
      return;
    }
    //("lasePrice==" + lastPrice.toString() + "==curPrice==" + curPrice.toString());
    canvas.drawLine(Offset(lastX, getY(lastPrice)),
        Offset(curX, getY(curPrice)), chartPaint..color = color);
  }

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: 10.0, color: color);
  }
}
