defmodule MiniD3fl.JobController.EventQueue do
  @moduledoc """
  優先度付きキューを使用して、時刻順に命令を管理するモジュール
  """

  # 初期化。空のキューとして :gb_trees.empty を使う
  def init_queue do
    :gb_trees.empty()
  end

  # コマンドをキューに挿入する関数
  def insert_command(queue, time, command, args) do
    # タプルとしてコマンドを構成し、時刻をキーにしてキューに挿入
    :gb_trees.insert(time, {time, command, args}, queue)
  end

  # 時刻順に最も早いコマンドを取得し、キューから削除
  def pop_command(queue) do
    case :gb_trees.take_smallest(queue) do
      {value, {time, command, args}, new_queue} ->
        IO.puts(value)
        {{time, command, args}, new_queue}
      _ ->
        {:empty, queue} #TODO: キューが空の場合のエラーハンドリング
    end
  end
end
