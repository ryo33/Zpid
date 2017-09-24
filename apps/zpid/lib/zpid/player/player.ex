defmodule Zpid.Player do
  use GenServer
  use Zpid.Display.Object

  import Zpid.EventDispatcher, only: [listen: 1, dispatch: 1]
  alias Zpid.Math.Vector
  alias Zpid.Player.Operation
  alias Zpid.Display
  alias Zpid.Display.Object.AnimatedSpriteState

  @width 32
  @height 42
  @frames Enum.map(0..3, fn i ->
    %{x: i * 32, y: 0, width: @width, height: @height}
  end)
  defobject %{
    walk: %{
      animated_sprite: %{
        image_url: "images/player.png",
        frames: @frames}}}
  @running_speed 4 / 60 # 4m per 60frames
  @walking_speed 1 / 60 # 1m per 60frames

  def start_link(id, user_id, display_id, parent_id) do
    GenServer.start_link(__MODULE__, {id, user_id, display_id, parent_id})
  end

  def init({id, user_id, display_id, parent_id}) do
    listen(Operation.by(id))
    state = %{
      id: id, user_id: user_id, display_id: display_id,
      x: 0.0, y: 0.0, rotation: 0, moving: false, running: false
    }
    dispatch(Display.Object.create(display_id, __MODULE__, id, to_object_state(state), parent_id))
    {:ok, state}
  end

  def handle_info(%Operation{action: :movement, value: value}, state) do
    speed = if state.running, do: @running_speed, else: @walking_speed
    x = value.x * speed
    y = value.y * speed
    {dx, dy} = Vector.rotate({x, y}, state.rotation + :math.pi/2)
    state = %{state |
      x: state.x + dx,
      y: state.y + dy,
      moving: true}
    dispatch(Display.Object.update(state.id, to_object_state(state)))
    {:noreply, state}
  end

  def handle_info(%Operation{action: :stop}, state) do
    state = %{state | moving: false}
    dispatch(Display.Object.update(state.id, to_object_state(state)))
    {:noreply, state}
  end

  def handle_info(%Operation{action: :rotation, value: radian}, state) do
    state = Map.update!(state, :rotation, fn rotation -> rotation + radian end)
    dispatch(Display.Object.update(state.id, to_object_state(state)))
    {:noreply, state}
  end

  def handle_info(%Operation{action: :start_dash}, state) do
    state = %{state | running: true}
    dispatch(Display.Object.update(state.id, to_object_state(state)))
    {:noreply, state}
  end

  def handle_info(%Operation{action: :end_dash}, state) do
    state = %{state | running: false}
    dispatch(Display.Object.update(state.id, to_object_state(state)))
    {:noreply, state}
  end

  defp to_object_state(state) do
    animation_speed = if state.running, do: 0.2, else: 0.1
    %{
      walk: %AnimatedSpriteState{
        x: state.x,
        y: state.y,
        scale_x: 0.4 / @width,
        scale_y: 0.6 / @height,
        anchor_x: 0.5,
        anchor_y: 0.5,
        rotation: state.rotation,
        animation_speed: animation_speed,
        play: state.moving}}
  end
end
