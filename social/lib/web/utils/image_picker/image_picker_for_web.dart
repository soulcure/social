import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:im/web/utils/image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// The web implementation of [ImagePickerPlatform].
///
/// This class implements the `package:image_picker` functionality for the web.
class ImagePickerPlugin extends ImagePickerPlatform {
  final ImagePickerPluginTestOverrides _overrides;
  bool get _hasOverrides => _overrides != null;
  final String _kImagePickerInputsDomId = '__image_picker_web-file-input';

  html.Element _target;

  /// A constructor that allows tests to override the function that creates file inputs.
  ImagePickerPlugin({
    @visibleForTesting ImagePickerPluginTestOverrides overrides,
  }) : _overrides = overrides {
    _target = _ensureInitialized(_kImagePickerInputsDomId);
  }

  /// Registers this class as the default instance of [ImagePickerPlatform].
  static void registerWith(Registrar registrar) {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  }

  /// Injects a file input with the specified accept+capture attributes, and
  /// returns the PickedFile that the user selected locally.
  ///
  /// `capture` is only supported in mobile browsers.
  /// See https://caniuse.com/#feat=html-media-capture
  @visibleForTesting
  Future<FileInfo> pickFile({
    String accept,
    String capture,
    bool multiple,
  }) {
    final html.FileUploadInputElement input =
        createInputElement(accept, capture, multiple);
    _injectAndActivate(input);
    return _getSelectedFile(input);
  }

  // DOM methods

  /// Converts plugin configuration into a proper value for the `capture` attribute.
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#capture
  @visibleForTesting
  String computeCaptureAttribute(ImageSource source, CameraDevice device) {
    if (source == ImageSource.camera) {
      return (device == CameraDevice.front) ? 'user' : 'environment';
    }
    return null;
  }

  html.File _getFileFromInput(html.FileUploadInputElement input) {
    if (_hasOverrides) {
      return _overrides.getFileFromInput(input);
    }
    return input?.files?.first;
  }

  List<html.File> _getFileListFromInput(html.FileUploadInputElement input) {
    if (_hasOverrides) {
      return [_overrides.getFileFromInput(input)];
    }
    return input?.files;
  }

  /// Handles the OnChange event from a FileUploadInputElement object
  /// Returns the objectURL of the selected file.
  String _handleOnChangeEvent(html.Event event) {
    final html.FileUploadInputElement input = event?.target;
    final html.File file = _getFileFromInput(input);

    if (file != null) {
      return html.Url.createObjectUrl(file);
    }
    return null;
  }

  /// Monitors an <input type="file"> and returns the selected file.
  Future<FileInfo> _getSelectedFile(html.FileUploadInputElement input) {
    final Completer<FileInfo> _completer = Completer<FileInfo>();
    // Observe the input until we can return something
    input.onChange.first.then((event) {
      final objectUrl = _handleOnChangeEvent(event);

      if (!_completer.isCompleted) {
        final html.File file = _getFileFromInput(input);

        _completer.complete(FileInfo(
            pickedFile: PickedFile(objectUrl),
            fileName: file.name,
            size: file.size,
            path: file.relativePath));
      }
    });
    input.onError.first.then((event) {
      if (!_completer.isCompleted) {
        _completer.completeError(event);
      }
    });
    // Note that we don't bother detaching from these streams, since the
    // "input" gets re-created in the DOM every time the user needs to
    // pick a file.
    return _completer.future;
  }

  /// Initializes a DOM container where we can host input elements.
  html.Element _ensureInitialized(String id) {
    var target = html.querySelector('#$id');
    if (target == null) {
      final html.Element targetElement =
          html.Element.tag('flt-image-picker-inputs')..id = id;

      html.querySelector('body').children.add(targetElement);
      target = targetElement;
    }
    return target;
  }

  /// Creates an input element that accepts certain file types, and
  /// allows to `capture` from the device's cameras (where supported)
  @visibleForTesting
  html.Element createInputElement(
      String accept, String capture, bool multiple) {
    if (_hasOverrides) {
      return _overrides.createInputElement(accept, capture);
    }

    final html.Element element = html.FileUploadInputElement()
      ..accept = accept
      ..multiple = multiple;

    if (capture != null) {
      element.setAttribute('capture', capture);
    }

    return element;
  }

  /// Injects the file input element, and clicks on it
  void _injectAndActivate(html.Element element) {
    _target.children.clear();
    _target.children.add(element);
    element.click();
  }

  Future<List<html.File>> pickFile2({
    String accept,
    String capture,
    bool multiple,
  }) {
    final html.FileUploadInputElement input =
        createInputElement(accept, capture, multiple);
    _injectAndActivate(input);
    return _getSelectedFile2(input);
  }

  Future<List<html.File>> _getSelectedFile2(html.FileUploadInputElement input) {
    final Completer<List<html.File>> _completer = Completer<List<html.File>>();
    // Observe the input until we can return something
    input.onChange.first.then((event) {
      if (!_completer.isCompleted) {
        final files = _getFileListFromInput(input);

        _completer.complete(files);
      }
    });
    input.onError.first.then((event) {
      if (!_completer.isCompleted) {
        _completer.completeError(event);
      }
    });
    // Note that we don't bother detaching from these streams, since the
    // "input" gets re-created in the DOM every time the user needs to
    // pick a file.
    return _completer.future;
  }
}

// Some tools to override behavior for unit-testing
/// A function that creates a file input with the passed in `accept` and `capture` attributes.
@visibleForTesting
typedef OverrideCreateInputFunction = html.Element Function(
  String accept,
  String capture,
);

/// A function that extracts a [html.File] from the file `input` passed in.
@visibleForTesting
typedef OverrideExtractFilesFromInputFunction = html.File Function(
  html.Element input,
);

/// Overrides for some of the functionality above.
@visibleForTesting
class ImagePickerPluginTestOverrides {
  /// Override the creation of the input element.
  OverrideCreateInputFunction createInputElement;

  /// Override the extraction of the selected file from an input element.
  OverrideExtractFilesFromInputFunction getFileFromInput;
}
