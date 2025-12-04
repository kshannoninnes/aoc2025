defmodule Grid do
  @doc """
  Parses a multiline string into a grid map keyed by `{x, y}` coordinates.

  The top-left character is at `{0, 0}`, `x` increases to the right,
  and `y` increases downward.

  ## Examples

      iex> grid = Grid.from_string("ab\\ncd")
      iex> Grid.at(grid, {0, 0})
      "a"
      iex> Grid.at(grid, {1, 1})
      "d"

  """
  def from_string(input) do
    input
    |> String.split("\n", trim: true)
    |> create_grid()
  end

  @doc """
  Updates the value at `{x, y}` in the grid and returns the new grid.

  If the coordinate is out of bounds, the grid is returned unchanged.

  ## Examples

      iex> grid = Grid.from_string("ab\\ncd")
      iex> grid = Grid.put(grid, {1, 0}, "X")
      iex> Grid.at(grid, {1, 0})
      "X"

  """
  def put(grid, coord, value) do
    Map.put(grid, coord, value)
  end

  @doc """
  Gets the value at `coord` in the grid, or returns `default` if it is missing.

  The default is `nil` when not provided.

  ## Examples

      iex> grid = Grid.from_string("ab\\ncd")
      iex> Grid.at(grid, {0, 1})
      "c"
      iex> Grid.at(grid, {5, 5}, "x")
      "x"
      iex> Grid.at(grid, {5, 5})
      nil

  """
  def at(grid, coord, default \\ nil), do: Map.get(grid, coord, default)

  @doc """
  Returns the width and height of the grid as `{width, height}`.

  ## Examples

      iex> grid = Grid.from_string("ab\\ncd")
      iex> Grid.get_size(grid)
      {2, 2}

  """
  def get_size(grid) do
    {max_x, max_y} =
      Enum.reduce(grid, {0, 0}, fn {{x, y}, _}, {mx, my} ->
        {max(mx, x), max(my, y)}
      end)

    {max_x + 1, max_y + 1}
  end

  @doc """
  Returns `true` if the coordinate `{x, y}` lies within `0..(width-1)` and `0..(height-1)`.

  ## Examples

      iex> Grid.in_bounds?({1, 1}, 3, 3)
      true

      iex> Grid.in_bounds?({-1, 0}, 3, 3)
      false

      iex> Grid.in_bounds?({3, 0}, 3, 3)
      false

  """
  def in_bounds?({x, y}, width, height) do
    x >= 0 and x < width and y >= 0 and y < height
  end

  @doc """
  Returns the 4-way neighbours (right, left, down, up) of a coordinate,
  excluding neighbours with negative coordinates.

  ## Examples

      iex> Grid.neighbours4({1, 1})
      [{2, 1}, {0, 1}, {1, 2}, {1, 0}]

      iex> Grid.neighbours4({0, 0})
      [{1, 0}, {0, 1}]

  """
  def neighbours4({x, y}) do
    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
    |> Enum.filter(fn {nx, ny} -> nx >= 0 and ny >= 0 end)
  end

  @doc """
  Returns the 8-way neighbours (including diagonals) of a coordinate,
  excluding neighbours with negative coordinates.

  ## Examples

      iex> Grid.neighbours8({1, 1})
      [
        {0, 0}, {1, 0}, {2, 0},
        {0, 1},         {2, 1},
        {0, 2}, {1, 2}, {2, 2}
      ]

      iex> Grid.neighbours8({0, 0})
      [{1, 0}, {0, 1}, {1, 1}]

  """
  def neighbours8({x, y}) do
    [
      {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
      {x - 1, y},                 {x + 1, y},
      {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1}
    ]
    |> Enum.filter(fn {nx, ny} -> nx >= 0 and ny >= 0 end)
  end

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
