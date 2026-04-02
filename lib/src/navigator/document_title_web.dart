// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Updates the browser tab title on web.
void setDocumentTitle(String title) {
  // ignore: deprecated_member_use
  html.document.title = title;
}
