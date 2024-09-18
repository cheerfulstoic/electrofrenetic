defmodule Electrofrenetic.Helpers do
  def clamp(number, minimum, maximum) do
    number
    |> max(minimum)
    |> min(maximum)
  end
end
