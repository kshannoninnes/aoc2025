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

run = fn label, contents ->
  IO.puts("[#{label}] Day #{day}.1: #{apply(module, :part1, [contents])}")
  IO.puts("[#{label}] Day #{day}.2: #{apply(module, :part2, [contents])}")
end

run.("TEST", File.read!("lib/day#{day}/test"))
IO.puts("")
run.("REAL", File.read!("lib/day#{day}/input"))
