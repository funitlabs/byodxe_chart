import '../k_chart_widget.dart';

/// Base Dimension
class BaseDimension {
  // the height of base chart
  double _mBaseHeight = 380;
  // the height of a secondary chart
  double _mSecondaryHeight = 0;
  // total height of chart
  double _mDisplayHeight = 0;
  // padding for secondary chart
  static const double _mSecondaryPadding = 20.0;

  // getter the secondary height
  double get mSecondaryHeight => _mSecondaryHeight;
  // getter the total height
  double get mDisplayHeight => _mDisplayHeight;

  /// constructor
  ///
  /// BaseDimension
  /// set _mBaseHeight
  /// compute value of _mSecondaryHeight, _mDisplayHeight
  BaseDimension({
    required double mBaseHeight,
    required Set<SecondaryState> secondaryStateLi,
  }) {
    _mBaseHeight = mBaseHeight;
    // 보조지표 영역의 높이를 메인 차트 높이의 40%로 증가
    _mSecondaryHeight = _mBaseHeight * 0.4;
    // 보조지표 개수에 따라 높이 계산, 각 보조지표마다 패딩 추가
    _mDisplayHeight = _mBaseHeight +
        (_mSecondaryHeight * secondaryStateLi.length) +
        (_mSecondaryPadding * secondaryStateLi.length);
  }
}
