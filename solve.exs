Mix.Task.run("app.start")

[arg] = System.argv()

day =
  case Integer.parse(arg) do
    {d, ""} when d >= 1 and d <= 12 ->
      d

    _ ->
      IO.puts("""
      Invalid day: #{inspect(arg)}
      Usage: mix day <1-12>
      """)
      exit({:shutdown, 1})
  end

module = Module.concat([:"Day#{day}"])

IO.puts("[DAY #{day}.1] Test #{day}.1: #{apply(module, :part1, [File.read!("lib/day#{day}/test") |> String.trim()])}")
IO.puts("[DAY #{day}.1] Real #{day}.1: #{apply(module, :part1, [File.read!("lib/day#{day}/input") |> String.trim()])}")

IO.puts("")

IO.puts("[DAY #{day}.1] Test #{day}.2: #{apply(module, :part2, [File.read!("lib/day#{day}/test") |> String.trim()])}")
IO.puts("[DAY #{day}.1] Real #{day}.2: #{apply(module, :part2, [File.read!("lib/day#{day}/input") |> String.trim()])}")
