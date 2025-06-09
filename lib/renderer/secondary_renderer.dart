import 'package:flutter/material.dart';
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart' show SecondaryState;
import 'base_chart_renderer.dart';
import '../utils/number_util.dart';

class SecondaryRenderer extends BaseChartRenderer<KLineEntity> {
  late double mMACDWidth;
  SecondaryState state;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  SecondaryRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      int fixedLength,
      this.chartStyle,
      this.chartColors)
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
          skipPadding: state == SecondaryState.MACD ||
              state == SecondaryState.KDJ ||
              state == SecondaryState.RSI ||
              state == SecondaryState.WR ||
              state == SecondaryState.CCI ||
              state == SecondaryState.VOL,
        ) {
    mMACDWidth = this.chartStyle.macdWidth;
  }

  @override
  void drawChart(KLineEntity lastPoint, KLineEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    switch (state) {
      case SecondaryState.VOL:
        // VOL 막대 및 MA5/MA10 라인 그리기
        double vol = curPoint.vol;
        double r = chartStyle.volWidth / 2;
        double top = getY(vol);
        double bottom = chartRect.bottom;
        if (vol != 0) {
          canvas.drawRect(
              Rect.fromLTRB(curX - r, top, curX + r, bottom),
              chartPaint
                ..color = curPoint.close > curPoint.open
                    ? this.chartColors.upColor
                    : this.chartColors.dnColor);
        }
        if (lastPoint.MA5Volume != 0 && curPoint.MA5Volume != 0) {
          drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX,
              this.chartColors.ma5Color);
        }
        if (lastPoint.MA10Volume != 0 && curPoint.MA10Volume != 0) {
          drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX,
              curX, this.chartColors.ma10Color);
        }
        break;
      case SecondaryState.MACD:
        if (curPoint.macd != null) {
          drawMACD(curPoint, canvas, curX, lastPoint, lastX);
        }
        break;
      case SecondaryState.KDJ:
        if (curPoint.k != null) {
          drawLine(lastPoint.k, curPoint.k, canvas, lastX, curX,
              this.chartColors.kColor);
          drawLine(lastPoint.d, curPoint.d, canvas, lastX, curX,
              this.chartColors.dColor);
          drawLine(lastPoint.j, curPoint.j, canvas, lastX, curX,
              this.chartColors.jColor);
        }
        break;
      case SecondaryState.RSI:
        if (curPoint.rsi != null) {
          drawLine(lastPoint.rsi, curPoint.rsi, canvas, lastX, curX,
              this.chartColors.rsiColor);
        }
        break;
      case SecondaryState.WR:
        drawLine(lastPoint.r, curPoint.r, canvas, lastX, curX,
            this.chartColors.rsiColor);
        break;
      case SecondaryState.CCI:
        if (curPoint.cci != null) {
          drawLine(lastPoint.cci, curPoint.cci, canvas, lastX, curX,
              this.chartColors.rsiColor);
        }
        break;
    }
  }

  void drawMACD(KLineEntity curPoint, Canvas canvas, double curX,
      KLineEntity lastPoint, double lastX) {
    double macd = curPoint.macd ?? 0;
    double macdY = getY(macd);
    double r = mMACDWidth / 2;
    double zeroy = getY(0);

    // MACD 바 그리기
    if (macd > 0) {
      canvas.drawRect(Rect.fromLTRB(curX - r, macdY, curX + r, zeroy),
          chartPaint..color = this.chartColors.upColor);
    } else {
      canvas.drawRect(Rect.fromLTRB(curX - r, zeroy, curX + r, macdY),
          chartPaint..color = this.chartColors.dnColor);
    }

    // DIF와 DEA 라인 그리기
    if (lastPoint.dif != null && curPoint.dif != null) {
      double lastDifY = getY(lastPoint.dif!);
      double curDifY = getY(curPoint.dif!);
      canvas.drawLine(Offset(lastX, lastDifY), Offset(curX, curDifY),
          chartPaint..color = this.chartColors.difColor);
    }

    if (lastPoint.dea != null && curPoint.dea != null) {
      double lastDeaY = getY(lastPoint.dea!);
      double curDeaY = getY(curPoint.dea!);
      canvas.drawLine(Offset(lastX, lastDeaY), Offset(curX, curDeaY),
          chartPaint..color = this.chartColors.deaColor);
    }
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
      case SecondaryState.VOL:
        children = [
          TextSpan(
              text: "VOL: ", style: getTextStyle(this.chartColors.volColor)),
          TextSpan(
              text:
                  "${NumberUtil.format(data.vol, format: NumberFormat.character)}    ",
              style: getTextStyle(this.chartColors.volColor)),
          if (data.MA5Volume != null && data.MA5Volume != 0)
            TextSpan(
                text:
                    "MA5: ${NumberUtil.format(data.MA5Volume!, format: NumberFormat.character)}    ",
                style: getTextStyle(this.chartColors.ma5Color)),
          if (data.MA10Volume != null && data.MA10Volume != 0)
            TextSpan(
                text:
                    "MA10: ${NumberUtil.format(data.MA10Volume!, format: NumberFormat.character)}    ",
                style: getTextStyle(this.chartColors.ma10Color)),
        ];
        break;
      case SecondaryState.MACD:
        children = [
          TextSpan(
              text: "MACD(12,26,9)    ",
              style: getTextStyle(this.chartColors.defaultTextColor)),
          if (data.macd != 0)
            TextSpan(
                text: "MACD:${format(data.macd)}    ",
                style: getTextStyle(this.chartColors.macdColor)),
          if (data.dif != 0)
            TextSpan(
                text: "DIF:${format(data.dif)}    ",
                style: getTextStyle(this.chartColors.difColor)),
          if (data.dea != 0)
            TextSpan(
                text: "DEA:${format(data.dea)}    ",
                style: getTextStyle(this.chartColors.deaColor)),
        ];
        break;
      case SecondaryState.KDJ:
        children = [
          TextSpan(
              text: "KDJ(9,1,3)    ",
              style: getTextStyle(this.chartColors.defaultTextColor)),
          if (data.k != 0)
            TextSpan(
                text: "K:${format(data.k)}    ",
                style: getTextStyle(this.chartColors.kColor)),
          if (data.d != 0)
            TextSpan(
                text: "D:${format(data.d)}    ",
                style: getTextStyle(this.chartColors.dColor)),
          if (data.j != 0)
            TextSpan(
                text: "J:${format(data.j)}    ",
                style: getTextStyle(this.chartColors.jColor)),
        ];
        break;
      case SecondaryState.RSI:
        children = [
          TextSpan(
              text: "RSI(14):${format(data.rsi)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.WR:
        children = [
          TextSpan(
              text: "WR(14):${format(data.r)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
      case SecondaryState.CCI:
        children = [
          TextSpan(
              text: "CCI(14):${format(data.cci)}    ",
              style: getTextStyle(this.chartColors.rsiColor)),
        ];
        break;
    }
    if (children != null) {
      TextPainter tp = TextPainter(
          text: TextSpan(children: children), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x, chartRect.top - topPadding));
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextPainter maxTp = TextPainter(
        text: TextSpan(text: "${format(maxValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    maxTp.layout();
    TextPainter minTp = TextPainter(
        text: TextSpan(text: "${format(minValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    minTp.layout();

    // Y축 텍스트 위치 조정
    maxTp.paint(canvas,
        Offset(chartRect.width - maxTp.width - 5, chartRect.top + topPadding));
    minTp.paint(
        canvas,
        Offset(chartRect.width - minTp.width - 5,
            chartRect.bottom - minTp.height - 5));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    // 상단 그리드 라인 추가
    canvas.drawLine(Offset(0, chartRect.top + topPadding),
        Offset(chartRect.width, chartRect.top + topPadding), gridPaint);

    // 하단 그리드 라인
    canvas.drawLine(Offset(0, chartRect.bottom - 5),
        Offset(chartRect.width, chartRect.bottom - 5), gridPaint);

    // 수직 그리드 라인
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= gridColumns; i++) {
      canvas.drawLine(Offset(columnSpace * i, chartRect.top + topPadding),
          Offset(columnSpace * i, chartRect.bottom - 5), gridPaint);
    }

    // 수평 그리드 라인
    double rowSpace = (chartRect.height - topPadding - 5) / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(
          Offset(0, chartRect.top + topPadding + rowSpace * i),
          Offset(chartRect.width, chartRect.top + topPadding + rowSpace * i),
          gridPaint);
    }
  }

  double getY(double value) {
    if (value.isNaN || value.isInfinite) return chartRect.bottom;
    if (maxValue == minValue) return chartRect.bottom;
    return (maxValue - value) * (chartRect.height / (maxValue - minValue)) +
        chartRect.top;
  }
}
