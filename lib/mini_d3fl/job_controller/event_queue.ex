defmodule MiniD3fl.JobController.EventQueue do
  @moduledoc """
  優先度付きキューを使用して、時刻順に命令を管理するモジュール
  """
  defmodule Event do
    @moduledoc"""
      time: float,
      event_name: atom,
      args: (args for event_name)
    """
    defstruct time: nil,
              event_name: nil,
              args: nil
  end

  # 初期化。空のキューとして :gb_trees.empty を使う
  def init_queue do
    :gb_trees.empty()
  end

  # コマンドをキューに挿入する関数
  def insert_command(queue, %Event{time: time, event_name: command, args: args} = event) do
    # タプルとしてコマンドを構成し、時刻をキーにしてキューに挿入
    #TODO: あとでcommandの間の優先順位をつけて、数値に変換するなど
    :gb_trees.insert({time, command, args}, event, queue)
  end

  # 時刻順に最も早いコマンドを取得し、キューから削除
  def pop_command({0, nil}) do
    {:empty, nil, nil}
  end

  def pop_command(queue) do
    {{time, _, _}, event, new_queue} = :gb_trees.take_smallest(queue)
    IO.puts(time)
    {:ok, event, new_queue}
  end
end
