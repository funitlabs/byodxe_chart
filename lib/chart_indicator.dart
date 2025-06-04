import 'package:flutter/material.dart';

/// MA 인디케이터 개별 설정 (기간과 색상)
class MAIndicatorConfig {
  /// MA 기간(일)
  final int day;

  /// 색상 (IndicatorColors의 color1~color10 중 하나 사용 권장)
  final Color color;

  const MAIndicatorConfig({
    required this.day,
    required this.color,
  });
}

/// 여러 개의 MA 인디케이터 설정을 담는 클래스 (최대 10개)
class MAIndicatorSettings {
  final List<MAIndicatorConfig> maList;

  MAIndicatorSettings(List<MAIndicatorConfig> maList)
      : assert(maList.length <= 10, '최대 10개까지 MA를 설정할 수 있습니다.'),
        maList = List.unmodifiable(maList);

  /// MA 기간(day) 리스트 반환
  List<int> get dayList => maList.map((e) => e.day).toList();
}

/// BOLL(볼린저밴드) 인디케이터 설정
class BOLLIndicatorConfig {
  /// 기간(일)
  final int day;

  /// 표준편차 계수
  final double k;

  /// UP 라인 표시 여부
  final bool showUp;

  /// MB 라인 표시 여부
  final bool showMb;

  /// DN 라인 표시 여부
  final bool showDn;

  /// UP 라인 색상 (IndicatorColors의 color1~color10 중 선택)
  final Color upColor;

  /// MB 라인 색상
  final Color mbColor;

  /// DN 라인 색상
  final Color dnColor;

  const BOLLIndicatorConfig({
    required this.day,
    required this.k,
    this.showUp = true,
    this.showMb = true,
    this.showDn = true,
    required this.upColor,
    required this.mbColor,
    required this.dnColor,
  });
}

/// EMA 인디케이터 개별 설정 (기간과 색상)
class EMAIndicatorConfig {
  /// EMA 기간(일)
  final int day;

  /// 색상 (IndicatorColors의 color1~color10 중 하나 사용 권장)
  final Color color;

  const EMAIndicatorConfig({
    required this.day,
    required this.color,
  });
}

/// 여러 개의 EMA 인디케이터 설정을 담는 클래스 (최대 10개)
class EMAIndicatorSettings {
  final List<EMAIndicatorConfig> emaList;

  EMAIndicatorSettings(List<EMAIndicatorConfig> emaList)
      : assert(emaList.length <= 10, '최대 10개까지 EMA를 설정할 수 있습니다.'),
        emaList = List.unmodifiable(emaList);

  /// EMA 기간(day) 리스트 반환
  List<int> get dayList => emaList.map((e) => e.day).toList();
}

/// SAR(Parabolic SAR) 인디케이터 설정
class SARIndicatorConfig {
  /// 초기 가속계수 (예: 0.02)
  final double start;

  /// 최대 가속계수 (예: 0.2)
  final double maximum;

  /// SAR 점 색상
  final Color dotColor;

  const SARIndicatorConfig({
    required this.start,
    required this.maximum,
    required this.dotColor,
  });
}

/// AVL(평균가격선) 인디케이터 설정
class AVLIndicatorConfig {
  /// AVL 선 색상
  final Color color;

  const AVLIndicatorConfig({
    required this.color,
  });
}
