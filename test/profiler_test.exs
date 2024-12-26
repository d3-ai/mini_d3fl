defmodule ProfilerTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  def sum(num) do
    IO.puts num
  end

  test "should use eporf" do
    :eprof.start_profiling([self()])

    # Do some work
    1..100 |> Enum.each(fn i ->
      spawn(fn -> sum(i + 1) end)
    end)

    :eprof.stop_profiling()
    :eprof.analyze()
  end

  #@tag timeout: :infinity
  #test "profile num mock" do
  #  :eprof.start_profiling([self()])
#
  #  NumMock.measure(2)
#
  #  :eprof.stop_profiling()
  #  :eprof.analyze()
  #end
end
