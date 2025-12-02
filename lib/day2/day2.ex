defmodule Day2 do
  def part1(input) do
    solve(input, &repeat_twice?/1)
  end

  def part2(input) do
    solve(input, &repeat_many?/1)
  end

  defp solve(input, repeat_func) do
    input
    |> String.split(",")
    |> Enum.map(&to_range/1)
    |> Enum.flat_map(&Enum.to_list/1)
    |> Enum.filter(fn id ->
      Integer.to_string(id)
      |> repeat_func.()
    end)
    |> Enum.sum()
  end

  defp to_range(str) do
    [a, b] = String.split(str, "-")
      String.to_integer(a)..String.to_integer(b)
  end

  defp repeat_twice?(s) do
    {a, b} = String.split_at(s, div(String.length(s), 2))
    a == b
  end

  # A string is periodic (repeats multiple times) if:
  # - we double it
  # - we remove the first and last character, and
  # - the original string is present in the new string
  # Source: https://www.baeldung.com/cs/check-string-periodicity
  # "If that’s the case, s will be a proper substring of ss (not starting at the 1st and the nth positions)"
  defp repeat_many?(original) do
    len = String.length(original)
    doubled = String.slice(original <> original, 1, len * 2 - 2)

    String.contains?(doubled, original)
  end
end
