# Starter scene (primitive, script, light, camera)

Values verified on Unity 6000.3 with the built-in render pipeline and MCP for Unity v10.3.0. Make each call on
its own, check the result, and read values back. Do not wrap them in `batch_execute`.

## Script

A minimal spinner that compiled clean on the first try:

```csharp
using UnityEngine;
public class Spinner : MonoBehaviour
{
    public float degreesPerSecond = 90f;
    public Vector3 axis = new Vector3(0.3f, 1f, 0.2f);
    void Update() => transform.Rotate(axis.normalized, degreesPerSecond * Time.deltaTime, Space.Self);
}
```

The component can only be added after the compile and domain reload have finished.

## Calls, in order

1. `manage_scene` action `create`, name and a folder path.
2. `manage_gameobject` action `create`, name `SpinCube`, `primitive_type` `Cube`, position `[0,0,0]`,
   rotation `[15,30,0]`.
3. `manage_components` action `add`, target `SpinCube`, `component_type` `Spinner`.
4. `manage_gameobject` action `create`, name `Directional Light`, `components_to_add` `["Light"]`, position
   `[0,3,0]`, rotation `[40,60,0]`.
5. `manage_components` action `set_property`, target `Directional Light`, `component_type` `Light`, properties
   `{"type":"Directional","intensity":1.0}`.
6. `manage_gameobject` action `create`, name `Main Camera`, tag `MainCamera`, `components_to_add`
   `["Camera","AudioListener"]`, position `[0,1.5,-4]`.
7. `manage_components` action `set_property`, target `Main Camera`, `component_type` `Camera`, properties
   `{"clearFlags":"SolidColor","fieldOfView":50,"backgroundColor":{"r":0.12,"g":0.13,"b":0.16,"a":1}}`.
8. `manage_gameobject` action `look_at`, target `Main Camera`, `look_at_target` `SpinCube`.
9. `manage_scene` action `save`.
10. `manage_camera` action `screenshot`, camera `Main Camera`, `capture_source` `game_view`, an output folder
    inside `Assets`.

## Lighting

- With the camera at (0, 1.5, -4) aimed at the origin, a light rotated (50, -30, 0) at intensity 1.2 lights all
  three visible cube faces at a similar angle and they clip to flat white. Rotated (40, 60, 0) at intensity 1.0 it
  gives a bright front, a lit top and a shaded right side.
- Rule of thumb: the light's forward vector should have a positive dot product with the outward normal of at
  least one visible face, so that face is in shade. Default skybox ambient adds roughly 0.2 to 0.3, so keep direct
  intensity at or below about 1.0 for the default white material.

## Proving motion (not yet tested through this plugin)

Save, enter play mode with `manage_editor`, wait about a second, take a screenshot, wait again, take another, then
stop and compare the two images. Plain play mode is a different thing from PlayMode tests, which hang on Linux.
