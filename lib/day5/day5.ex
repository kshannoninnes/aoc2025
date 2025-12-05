defmodule Day5 do
  def part1(input) do
    [ranges, ingredients] =
      input
      |> String.split("\n\n", trim: true)

    ranges =
      ranges
      |> String.split("\n")
      |> Enum.map(&convert_to_range/1)
      |> merge_ranges()

    ingredients
    |> String.split("\n")
    |> Enum.map(&String.to_integer/1)
    |> Enum.count(fn id -> in_any_range?(id, ranges) end)
  end

  def part2(input) do
    [ranges, _ingredients] =
      input
      |> String.split("\n\n", trim: true)

    ranges
    |> String.split("\n")
    |> Enum.map(&convert_to_range/1)
    |> merge_ranges()
    |> Enum.sum_by(fn range -> Range.size(range) end)
  end

  defp convert_to_range(range_str) do
    range_str
    |> String.split("-")
    |> Enum.map(&String.to_integer/1)
    |> then(fn [start, stop] -> start..stop end)
  end

  defp merge_ranges(ranges) do
    ranges
    |> Enum.sort_by(fn range_start..range_stop -> range_start end)
    |> Enum.reduce([], &merge_overlapping_range/2)
    |> Enum.reverse()
  end

  # No more ranges, we're done
  defp merge_overlapping_range(range, []), do: [range]

  # More ranges, attempt to merge
  defp merge_overlapping_range(curr_start..curr_end, [prev_start..prev_end | rest]) do
    if curr_start <= prev_end + 1 do
      # Merge the ranges
      [prev_start..max(prev_end, curr_end) | rest]
    else
      # Leave ranges untouched
      [curr_start..curr_end, prev_start..prev_end | rest]
    end
  end

  def in_any_range?(n, ranges) do
    binary_search(n, ranges, 0, length(ranges) - 1)
  end

  # Finished looking, id not in any ranges
  defp binary_search(_id, _ranges, low, high) when low > high, do: false

  # Look for range that id belongs to
  defp binary_search(id, ranges, low, high) do
    median = div(low + high, 2)
    range_start..range_end = Enum.fetch!(ranges, median)

    cond do
      # id is lower than range start (which is from the median range between low and high)
      # therefore repeat binary_search with a new, lower, median.
      id < range_start ->
        binary_search(id, ranges, low, median - 1)

      # id is higher than range_end (which is from the median range between low and high)
      # therefore repeat binary_search with a new, higher, median
      id > range_end ->
        binary_search(id, ranges, median + 1, high)

      # id is not lower than range_start, and not higher than range_end, which means it's within the range!
      true ->
        true
    end
  end
end
