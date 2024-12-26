defmodule Profiler do
  def start_profile() do
    {:ok, file} = File.open("tmp/output.txt", [:write])
    original_leader = Process.group_leader()

    # 標準出力をファイルにリダイレクト
    Process.group_leader(self(), file)

    :eprof.start_profiling([self()])

    # Do some work
    1..100 |> Enum.each(fn i ->
      spawn(fn -> i + 1 end)
    end)

    :eprof.stop_profiling()
    :eprof.analyze()

    Process.group_leader(self(), original_leader)
    File.close(file)
  end

  def num_mock_pro() do
    {:ok, file} = File.open("tmp/num_mock_profiler_output.txt", [:write])
    original_leader = Process.group_leader()

    # 標準出力をファイルにリダイレクト
    Process.group_leader(self(), file)
    :eprof.start_profiling([self()])

    NumMock.measure(2)

    :eprof.stop_profiling()
    :eprof.analyze()
    # リダイレクトを元に戻す
    Process.group_leader(self(), original_leader)

    File.close(file)
  end
end
