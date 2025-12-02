defmodule Day1 do
  def part1(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.map_reduce(50, fn step, pos -> { move(pos, step), move(pos, step) } end)
    |> elem(0) #                              Current Ans.      Current Pos.
    |> Enum.count(fn x -> x == 0 end)
  end
  def part2(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_line/1)
    |> Enum.map_reduce(50, fn step, pos -> { click(pos, step), move(pos, step) } end)
    |> elem(0)
    |> Enum.sum
  end

  defp parse_line(line) do
    {dir, num} = String.split_at(line, 1)
    {dir, String.to_integer(num)}
  end

  defp move(pos, {"L", n}), do: Integer.mod(pos - n, 100)
  defp move(pos, {"R", n}), do: Integer.mod(pos + n, 100)

  # Have to 'mirror the dial' so L moves become R moves
  defp click(pos, {"L", n}), do: rem(100 - pos, 100) |> click({"R", n})
  defp click(pos, {"R", n}), do: div(pos + n, 100)
end
