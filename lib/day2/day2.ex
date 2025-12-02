defmodule Day2 do
  require Integer

  def part1(input) do
    input
    |> get_ranges()
    |> Enum.flat_map(&get_ids_from_range/1)
    |> Enum.filter(&invalid_part1?/1)
    |> Enum.sum()
  end

  def part2(input) do
    input
    |> get_ranges()
    |> Enum.flat_map(&get_ids_from_range/1)
    |> Enum.filter(&invalid_part2?/1)
    |> Enum.sum()
  end

  defp invalid_part1?(id), do: Integer.to_string(id) |> repeat_twice?()
  defp invalid_part2?(id), do: Integer.to_string(id)|> repeat_many?()

  defp get_ranges(input), do: String.split(input, ",")

  defp get_ids_from_range(range_string) do
    [a, b] = String.split(range_string, "-")
    a = String.to_integer(a)
    b = String.to_integer(b)
    Enum.to_list(a..b)
  end

  def repeat_twice?(s) do
    len = String.length(s)
    half = div(len, 2)

    rem(len, 2) == 0 and
    String.slice(s, 0, half) == String.slice(s, half, half)
  end

  defp repeat_many?(str) do
    doubled = str <> str
    len = String.length(str)
    inner = String.slice(doubled, 1, len * 2 - 2)

    String.contains?(inner, str)
  end
end
