defmodule Day4 do
  # Part 1 is relatively simple compared to Part 2:
  # - For all non-empty cells, if fewer than 4 non-empty neighbours, count it
  def part1(input) do
    grid = Grid.from_string(input)
    bounds = Grid.get_size(grid)

    Enum.count(grid, fn cell -> removable?(grid, bounds, cell) end)
  end

  # Part 2 required not just counting removable cells, but actually removing them
  # In addition, you have to repeat the process on the neighbours of any cell you
  # remove, to ensure already-processed neighbours get re-processed, just in case
  # they become eligible for removal.
  def part2(input) do
    grid = Grid.from_string(input)
    bounds = Grid.get_size(grid)

    final_grid =
      Enum.reduce(grid, grid, fn cell, acc ->
        remove_recursively(acc, bounds, cell)
      end)

    count_removed(grid, final_grid)
  end

  # Determine if a cell can be removed
  defp removable?(grid, bounds, {coord, _value}) do
    neighbour_coords = neighbour_coords(bounds, coord)

    # Count how many populated neighbours this cell has
    total_neighbours =
      neighbour_coords
      |> Enum.count(fn ncoord -> Grid.at(grid, ncoord) == "@" end)

    total_neighbours < 4
  end

  # Skip empty cells
  defp remove_recursively(grid, _bounds, {_coord, "."}), do: grid

  # Try to remove "@"
  defp remove_recursively(grid, bounds, cell = {coord, value}) do
    if removable?(grid, bounds, cell) do
      # Remove cell
      grid = Grid.put(grid, coord, ".")

      neighbour_coords = neighbour_coords(bounds, coord)

      # Try to remove neighbours of cell just removed
      Enum.reduce(neighbour_coords, grid, fn ncoord, acc ->
        next_cell = {ncoord, Grid.at(acc, ncoord)}
        remove_recursively(acc, bounds, next_cell)
      end)
    else
      # Can't remove it so grid left unchanged
      grid
    end
  end

  # Get neighbor coordinates
  defp neighbour_coords({width, height}, coord) do
    coord
    |> Grid.neighbours8()
    |> Enum.filter(&Grid.in_bounds?(&1, width, height))
  end

  # Count how many cells changed between original and final grids
  defp count_removed(original_grid, final_grid) do
    Enum.count(original_grid, fn {coord, orig_val} ->
      final_grid[coord] != orig_val
    end)
  end
end
