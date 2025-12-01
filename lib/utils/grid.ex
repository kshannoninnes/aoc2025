defmodule Grid do
  def from_string(input) do
    input
    |> String.split("\n", trim: true)
    |> create_grid()
  end

  def get_size(grid) do
    {max_x, max_y} =
      Enum.reduce(grid, {0, 0}, fn {{x, y}, _}, {mx, my} ->
        {max(mx, x), max(my, y)}
      end)

    {max_x + 1, max_y + 1}
  end

  def in_bounds?({x, y}, width, height) do
    x >= 0 and x < width and y >= 0 and y < height
  end

  def neighbors4({x, y}) do
    [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
  end

  def neighbors8({x, y}) do
    [{x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
    {x - 1, y},                  {x + 1, y},
    {x - 1, y + 1},  {x, y + 1}, {x + 1, y + 1}]
  end

  def at(grid, coord, default \\ nil), do: Map.get(grid, coord, default)

  # Private Helper
  defp create_grid(lines) do
    lines
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {ch, x} ->
        {{x, y}, ch}
      end)
    end)
    |> Map.new()
  end
end
