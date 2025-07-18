Terrain Settings
################

.. omw-setting::
   :title: distant terrain
   :type: boolean
   :range: true, false
   :default: false
   :location: :bdg-success:`Launcher > Settings > Visuals > Terrain`

   Controls whether the engine will use paging (chunking) and LOD algorithms to load the terrain of the entire world at all times.
   Otherwise, only the terrain of the surrounding cells is loaded.

   .. note::
      When enabling distant terrain, make sure the 'viewing distance' in the camera section is set to a larger value so
      that you can actually see the additional terrain and objects.

   To avoid frame drops as the player moves around, nearby terrain pages are always preloaded in the background,
   regardless of the preloading settings in the 'Cells' section,
   but the preloading of terrain behind a door or a travel destination, for example,
   will still be controlled by cell preloading settings.

.. omw-setting::
   :title: vertex lod mod
   :type: int
   :range: any
   :default: 0

   Controls only the Vertex LOD of the terrain. The amount of terrain chunks and the detail of composite maps is left unchanged.

   Must be changed in increments of 1. Each increment will double (for positive values) or halve (for negative values) the number of vertices rendered.
   For example: -2 means 4x reduced detail, +3 means 8x increased detail.

   Note this setting will typically not affect near terrain. When set to increase detail, the detail of near terrain can not be increased
   because the detail is simply not there in the data files, and when set to reduce detail,
   the detail of near terrain will not be reduced because it was already less detailed than the far terrain (in view relative terms) to begin with.

.. omw-setting::
   :title: lod factor
   :type: float32
   :range: >0
   :default: 1.0

   Controls the level of detail if distant terrain is enabled.
   Higher values increase detail at the cost of performance, lower values reduce detail but increase performance.

   Note: it also changes how the Quad Tree is split.
   Increasing detail with this setting results in the visible terrain being divided into more chunks,
   where as reducing detail with this setting would reduce the number of chunks.

   Fewer terrain chunks is faster for rendering, but on the other hand a larger proportion of the entire terrain
   must be rebuilt when LOD levels change as the camera moves.
   This could result in frame drops if moving across the map at high speed.

   For this reason, it is not recommended to change this setting if you want to change the LOD.
   If you want to do that, first try using the 'vertex lod mod' setting to configure the detail of the terrain outlines
   to your liking and then use 'composite map resolution' to configure the texture detail to your liking.
   But these settings can only be changed in multiples of two, so you may want to adjust 'lod factor' afterwards for even more fine-tuning.

.. omw-setting::
   :title: composite map level
   :type: int
   :range: ≥ -3
   :default: 0

   Controls at which minimum size (in 2^value cell units) terrain chunks will start to use a composite map instead of the high-detail textures.
   With value -3 composite maps are used everywhere.

   A composite map is a pre-rendered texture that contains all the texture layers combined.
   Note that resolution of composite maps is currently always fixed at 'composite map resolution',
   regardless of the resolution of the underlying terrain textures.
   If high resolution texture replacers are used, it is recommended to increase 'composite map resolution' setting value.

.. omw-setting::
   :title: composite map resolution
   :type: int
   :range: >0
   :default: 512

   Controls the resolution of composite maps. Larger values result in increased detail,
   but may take longer to prepare and thus could result in longer loading times and an increased chance of frame drops during play.
   As with most other texture resolution settings, it's most efficient to use values that are powers of two.

   An easy way to observe changes to loading time is to load a save in an interior next to an exterior door
   (so it will start preloding terrain) and watch how long it takes for the 'Composite' counter on the F4 panel to fall to zero.

.. omw-setting::
   :title: max composite geometry size
   :type: float32
   :range: ≥1.0
   :default: 4.0

   Controls the maximum size of simple composite geometry chunk in cell units. With small values there will more draw calls and small textures,
   but higher values create more overdraw (not every texture layer is used everywhere).

.. omw-setting::
   :title: debug chunks
   :type: boolean
   :range: true, false
   :default: false

   This debug setting allows you to see the borders of each chunks of the world by drawing lines around them (as with toggleborder). 
   If object paging is set to true then this debug setting will allows you to see what objects have been merged in the scene
   by making them colored randomly.

.. omw-setting::
   :title: object paging
   :type: boolean
   :range: true, false
   :default: true

   Controls whether the engine will use paging (chunking) algorithms to load non-terrain objects
   outside of the active cell grid.

   Depending on the settings below every object in the game world has a chance
   to be batched and be visible in the game world, effectively allowing
   the engine to render distant objects with a relatively low performance impact automatically.

   In general, an object is more likely to be batched if the number of the object's vertices
   and the corresponding memory cost of merging the object is low compared to
   the expected number of the draw calls that are going to be optimized out.
   This memory cost and the saved number of draw calls shall be called
   the "merging cost" and the "merging benefit" in the following documentation.

   Objects that are scripted to disappear from the game world
   will be handled properly as long as their scripts have a chance to actually disable them.

   This setting has no effect if distant terrain is disabled.

.. omw-setting::
   :title: object paging active grid
   :type: boolean
   :range: true, false
   :default: true
   :location: :bdg-success:`Launcher > Settings > Visuals > Terrain`

   Controls whether the objects in the active cells use the mentioned paging algorithms.
   Active grid paging significantly improves the framerate when your setup is CPU-limited.

   .. note::
      There is a limit of light sources which may affect a rendering shape at the moment.
      If this limit is too small, lighting issues arising due to merged objects
      being considered a single object, and they may disrupt your gameplay experience.
      Consider increasing the 'max lights' setting value in the 'Shaders' section to avoid this issue.
      With the Legacy lighting mode this limit can not be increased (only 8 sources can be used).

.. omw-setting::
   :title: object paging merge factor
   :type: float32
   :range: >0
   :default: 250.0

   Affects the likelihood of more complex objects to get paged.
   Higher values improve visual fidelity at the cost of performance and RAM.

   Technically this factor is a multiplier of merging benefit and affects the decision
   whether displaying the object is cheap enough to justify the sacrifices.

.. omw-setting::
   :title: object paging min size
   :type: float32
   :range: >0
   :default: 0.01
   :location: :bdg-success:`Launcher > Settings > Visuals > Terrain`

   Controls how large an object must be to be visible in the scene.
   The object's size is divided by its distance to the camera
   and the result of the division is compared with this value.
   The smaller this value is, the more objects you will see in the scene.

.. omw-setting::
   :title: object paging min size merge factor
   :type: float32
   :range: >0
   :default: 0.3

   This setting gives inexpensive objects a chance to be rendered from a greater distance
   even if the engine would rather discard them according to the previous setting.

   It controls the factor that the minimum size is multiplied by
   roughly according to the following formula:

   .. math::

      \begin{aligned}
      \text{factor} &= \text{merge cost} \cdot \frac{\text{min size cost multiplier}}{\text{merge benefit}} \\
      \text{factor} &= \text{factor} + (1 - \text{factor}) \cdot \text{min size merge factor}
      \end{aligned}

   Since the larger this factor is, the smaller chance a large object has to be rendered,
   decreasing this value makes more objects visible in the scene
   without impacting the performance as dramatically as the minimum size setting.

.. omw-setting::
   :title: object paging min size cost multiplier
   :type: float32
   :range: >0
   :default: 25.0

   This setting adjusts the calculated cost of merging an object used in the mentioned functionality.
   The larger this value is, the less expensive objects can be before they are discarded.
   See the formula above to figure out the math.

.. omw-setting::
   :title: water culling
   :type: boolean
   :range: true, false
   :default: true

   Controls whether water culling is used.

   Water culling is an optimisation that prevents the expensive rendering of water when it is
   evaluated to be below any visible terrain chunk, potentially improving performance in many scenes.

   You may want to opt out of it if it causes framerate instability or inappropriately invisible water on your setup.
