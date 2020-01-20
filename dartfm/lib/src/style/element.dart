import 'package:flutter/rendering.dart';
import 'package:kraken/element.dart';
import 'package:kraken/style.dart';

mixin ElementStyleMixin on RenderBox {
  // Loop element tree to find nearest parent width include self node
  // @TODO Support detecting node width in more complicated scene such as flex layout
  double getParentWidth(int childId) {
    String width;
    bool isParentWithWidth = false;
    Element childNode = nodeMap[childId];
    Style parentStyle;
    double cropWidth = 0;
    while (!isParentWithWidth) {
      Style style = childNode.style;
      if (style.contains('width')) {
        isParentWithWidth = true;
        width = style['width'];
        parentStyle = style;
        break;
      }
      if (childNode is Element) {
        cropWidth +=
            ((childNode.cropWidth ?? 0) + (childNode.cropBorderWidth ?? 0));
      }
      if (childNode.parentNode != null) {
        childNode = childNode.parentNode;
      }
    }

    double widthD = Length.toDisplayPortValue(width) - cropWidth;

    Padding padding = baseGetPaddingFromStyle(parentStyle);
    widthD = widthD - padding.left - padding.right;

    return widthD;
  }

  // get parent node height if parent is flex and stretch children height
  double getStretchParentHeight(int nodeId) {
    double parentHeight;
    Element parentNode = nodeMap[nodeId].parent;

    if (parentNode != null && parentNode.style != null) {
      Style parentStyle = parentNode.style;

      if (parentStyle.contains('display') &&
          parentStyle['display'] == 'flex' &&
          parentStyle['flexDirection'] == 'row' &&
          parentStyle.contains('height') &&
          (!parentStyle.contains('alignItems') ||
              (parentStyle.contains('alignItems') &&
                  parentStyle['alignItems'] == 'stretch'))) {
        parentHeight = Length.toDisplayPortValue(parentStyle['height']);
      }
    }
    return parentHeight;
  }

  // Whether current node is inline
  bool isElementInline(String defaultDisplay, int nodeId) {
    var node = nodeMap[nodeId];
    var parentNode = node.parentNode;

    String display = defaultDisplay;

    // Display as inline-block if parent node is flex and with align-items not stretch
    if (parentNode != null) {
      Style style = parentNode.style;

      if (style.contains('display') && style['display'] == 'flex') {
        display = 'inline-block';

        if (style.contains('flexDirection') &&
            style['flexDirection'] == 'column' &&
            (!style.contains('alignItems') ||
                (style.contains('alignItems') &&
                    style['alignItems'] == 'stretch'))) {
          display = 'block';
        }
      }
    }

    if (display == 'flex' || display == 'block') {
      return false;
    }
    return true;
  }
}
