import 'package:flutter/material.dart';

/// Global route observer enabling widgets like [HomeView] to react to
/// page route push/pop transitions and pause expensive shaders.
///
/// Uses [PageRoute] so modal dialogs (like EditUserNameDialog) do not
/// pause background animations, while full-screen page transitions do.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
