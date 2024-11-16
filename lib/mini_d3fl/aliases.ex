defmodule MiniD3fl.Aliases do
  defmacro __using__(_) do
    quote do
      alias MiniD3fl.ComputeNode
      alias MiniD3fl.ComputeNode.{Model, InitArgs, TrainArgs, SendArgs, RecvArgs, RenewModelArgs}
      alias MiniD3fl.Utils
      alias MiniD3fl.Channel
      alias MiniD3fl.Channel.{ChannelArgs, QoS}
      alias MiniD3fl.JobController
      alias MiniD3fl.JobController.EventQueue
      alias MiniD3fl.JobController.EventQueue.Event
      alias MiniD3fl.JobExecutor
      alias MiniD3fl.JobExecutor.JobExcInitArgs
    end
  end
end
