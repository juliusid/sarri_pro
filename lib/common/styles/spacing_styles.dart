import 'package:flutter/material.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';

class TSSpacingStyle {
  static const EdgeInsetsGeometry paddingWithAppBarHeight = 
    EdgeInsets.only(
      top: TSizes.appBarHeight,
      left: TSizes.defaultSpace,
      bottom: TSizes.defaultSpace,
      right: TSizes.defaultSpace,
    );
}
