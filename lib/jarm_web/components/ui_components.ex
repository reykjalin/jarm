defmodule JarmWeb.UiComponents do
  use Phoenix.Component

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "my-5 p-5 md:p-10 border border-zinc-400 rounded-md bg-slate-800 light:bg-white",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
