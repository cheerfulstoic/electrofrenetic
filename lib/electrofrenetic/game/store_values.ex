defmodule Electrofrenetic.Game.StoreValues do
  def adjust(:energy, value, func) do
    new_value = func.(value)

    cond do
      new_value < 0.0 -> :error
      new_value > 100.0 -> 100.0
      true -> new_value
    end
  end
end
