defmodule MiniD3fl.Aliases do
  defmacro __using__(_) do
    quote do
      alias FedAvg
      alias MiniD3fl.ComputeNode
      alias MiniD3fl.ComputeNode.{Model, InitArgs, TrainArgs, SendArgs, RecvArgs, RenewModelArgs}
      alias MiniD3fl.Channel
      alias MiniD3fl.Channel.{ChannelArgs, QoS}
      alias MiniD3fl.Data
      alias MiniD3fl.DataLoader
      alias MiniD3fl.JobController
      alias MiniD3fl.JobController.EventQueue
      alias MiniD3fl.JobController.EventQueue.Event
      alias MiniD3fl.JobExecutor
      alias MiniD3fl.JobExecutor.JobExcInitArgs
      alias MiniD3fl.Utils
    end
  end
end
