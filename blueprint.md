
# 3D Game Engine with Flutter Blockly

## Overview

This project aims to create a simple 3D game engine using Flutter. The engine will use `flutter_blockly` as a visual scripting interface to control objects in a 3D scene rendered with `flutter_cube`.

## Features

*   **Visual Scripting:** Use a Blockly-based editor to create game logic without writing code.
*   **3D Rendering:** Display and manipulate 3D objects in a scene.
*   **Object Control:** Control the position, rotation, and scale of 3D objects through visual scripting.

## Design

*   **UI:** The UI will be split into two main parts:
    *   A Blockly editor for creating and editing visual scripts.
    *   A 3D view to display the game scene.
*   **State Management:** A `StatefulWidget` will manage the state of the 3D scene and the Blockly editor.
*   **Blockly Integration:**
    *   Custom blocks will be defined for 3D object manipulation (e.g., move, rotate, scale).
    *   The generated JavaScript code from Blockly will be executed to control the 3D objects.
*   **3D Scene:**
    *   The `flutter_cube` package will be used to render a simple 3D scene with a single object (a cube to start).

## Current Plan

*   Create the basic UI structure with a Blockly editor and a 3D view.
*   Define custom Blockly blocks for controlling the 3D object.
*   Implement the logic to "run" the Blockly code and update the 3D scene.
