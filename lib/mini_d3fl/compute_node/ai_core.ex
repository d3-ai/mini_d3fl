defmodule MiniD3fl.ComputeNode.AiCore do
  use GenServer
  alias Mnist
  alias Cifar10

  def init(init_arg) do
    {:ok, init_arg}
  end

  def run(former_model \\ %{}, data_name, client_id, client_num, sample_rate) do
    case data_name do
      :mnist ->
        IO.puts("Mnist")
        Mnist.run(former_model, client_id, client_num, sample_rate)

      :cifar10 ->
        IO.puts("Cifar10")
        Cifar10.run(former_model, client_id, client_num, sample_rate)
      _ -> IO.puts "Not Implemented"
    end
  end
  def data_download(:mnist, client_num, sample_rate) do
    Mnist.data_download(:mnist, client_num, sample_rate)
  end

  def data_download(:cifar10, client_num, sample_rate) do
    Cifar10.data_download(:cifar10, client_num, sample_rate)
  end

  def aggregate(:fedavg, maps) do
    FedAvg.average(maps)
  end
end
