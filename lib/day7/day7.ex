defmodule Day7 do
  def part1(input) do
    grid =
      input
      |> Grid.from_string()

    {grid_height, _grid_width} = Grid.get_size(grid)

    {{start_col, start_row}, _val} =
      grid
      |> Enum.find(fn {_coords, val} -> val == "S" end)

    splitter_list =
      grid
      |> Enum.filter(fn {_coords, val} -> val == "^" end)
      |> Enum.map(fn {coords, _val} -> coords end)

    count_splits([{start_col, start_row + 1}], splitter_list, 0, grid_height)
  end

  # When we run out of beams (from dropping any that move off-grid), we're done.
  defp count_splits([], _splitter_list, total_splits, _max_row), do: total_splits

  defp count_splits(beam_list, splitter_list, total_splits, max_row) do

    # Split the active beams into:
    #   - beams currently sitting on a splitter (these will branch)
    #   - beams on normal cells (these will continue straight)
    {beams_on_splitters, regular_beams} =
      beam_list
      |> Enum.split_with(fn beam_coord -> beam_coord in splitter_list end)

    new_beams =
      beams_on_splitters

      # Merge the splitter and regular beams, replacing each of the splitter beams with 2 new outgoing beams
      |> Enum.reduce(regular_beams, fn {col, row}, acc ->
        [{col - 1, row}, {col + 1, row} | acc]
      end)

      # Remove duplicate beams that may have converged to the same position.
      |> Enum.uniq()

      # Advance all beams one row downward.
      # Any beams that move past the grid's bottom are dropped.
      |> Enum.map(fn {col, row} -> {col, row + 1} end)
      |> Enum.reject(fn {_col, row} -> row > max_row end)

    count_splits(new_beams, splitter_list, total_splits + length(beams_on_splitters), max_row)
  end

  def part2(input) do
    grid =
      input
      |> Grid.from_string()

    {max_height, _width} = Grid.get_size(grid)

    {start_position, _val} =
      grid
      |> Enum.find(fn {_coords, val} -> val == "S" end)

    splitter_positions =
      grid
      |> Enum.filter(fn {_coords, val} -> val == "^" end)
      |> Enum.map(fn {coords, _val} -> coords end)
      |> MapSet.new()

    {total_paths, _memo} =
      count_paths(start_position, splitter_positions, max_height, Map.new())

    total_paths
  end

  # A DFS-like count with memoization to prevent recalculating the same count multiple times
  defp count_paths({col, row} = position, splitter_positions, max_height, memo) do
    cond do
      # If we've already calculated this position, reuse it.
      Map.has_key?(memo, position) ->
        {Map.fetch!(memo, position), memo}

      # Bottom row: reaching any valid cell here is 1 complete path.
      row == max_height ->
        {1, Map.put(memo, position, 1)}

      # Default case
      true ->
        next_row = row + 1

        # These are returned from the if-expression below
        {path_count, memo_after} =

          # Next cell is a splitter: beam splits into left and right.
          if MapSet.member?(splitter_positions, {col, next_row}) do

            # Calculate the counts for both left and right sub-trees
            {left_count, memo_left} =
              count_paths({col - 1, next_row}, splitter_positions, max_height, memo)

            {right_count, memo_right} =
              count_paths({col + 1, next_row}, splitter_positions, max_height, memo_left)

            # Sum the counts, and memo_right already includes all the entries from memo_left
            {left_count + right_count, memo_right}

          # Normal cell: beam continues straight down.
          else
            count_paths({col, next_row}, splitter_positions, max_height, memo)
          end

        {path_count, Map.put(memo_after, position, path_count)}
    end
  end
end
