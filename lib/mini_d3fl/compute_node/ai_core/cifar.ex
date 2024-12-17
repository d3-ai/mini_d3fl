defmodule Cifar10 do
  require Axon
  use MiniD3fl.Aliases
  alias MiniD3fl.DataLoader
  alias MiniD3fl.DataLoader.MlData
  @batch_size 32
  @channel_value_max 255
  @label_values Enum.to_list(0..9)
  @width 32
  @height 32
  @channels 3

  defp transform_images({bin, type, shape}) do
    bin
    |> Nx.from_binary(type)
    |> Nx.reshape(shape, names: [:count, :channels, :width, :height])
    # Move channels to last position to match what conv layer expects
    |> Nx.transpose(axes: [:count, :width, :height, :channels])
    |> Nx.divide(@channel_value_max)
    |> Nx.to_batched(@batch_size)
    |> Enum.split(1500)
  end

  defp transform_labels({bin, type, _}) do
    bin
    |> Nx.from_binary(type)
    |> Nx.new_axis(-1)
    |> Nx.equal(Nx.tensor(@label_values))
    |> Nx.to_batched(@batch_size)
    |> Enum.split(1500)
  end

  defp build_model(input_shape) do
    Axon.input("input", shape: input_shape)
    |> Axon.conv(32, kernel_size: {3, 3}, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2})
    |> Axon.conv(64, kernel_size: {3, 3}, activation: :relu)
    |> Axon.batch_norm()
    |> Axon.max_pool(kernel_size: {2, 2})
    |> Axon.flatten()
    |> Axon.dense(64, activation: :relu)
    |> Axon.dropout(rate: 0.5)
    |> Axon.dense(length(@label_values), activation: :softmax)
  end

  defp train_model(model, train_images, train_labels, epochs) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, :adam)
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(Stream.zip(train_images, train_labels), %{}, epochs: epochs, compiler: EXLA)
  end

  defp test_model(model, model_state, test_images, test_labels) do
    model
    |> Axon.Loop.evaluator()
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(Stream.zip(test_images, test_labels), model_state, compiler: EXLA)
  end

  def data_download(:cifar10, client_num, sample_rate) do
    {images, labels} = Scidata.CIFAR10.download()
    {all_local_images, global_test_images} = transform_images(images)
    {all_local_labels, global_test_labels} = transform_labels(labels)

    {all_local_images_train, all_local_images_valid} = Enum.split(all_local_images, 1250)
    {all_local_labels_train, all_local_labels_valid} = Enum.split(all_local_labels, 1250)

    locals_train = client_data_split(all_local_images_train, all_local_labels_train, client_num, sample_rate)
    locals_valid = client_data_split(all_local_images_valid, all_local_labels_valid, client_num, sample_rate)

    %MlData{
      locals_train: locals_train,
      locals_valid: locals_valid,
      global_test: {global_test_images, global_test_labels}
    }
  end

  def client_data_split(local_images, local_labels, client_num, sample_rate \\ 0.2) when length(local_images) == length(local_labels) do
    len = length(local_images)
    sample_size = round(len * sample_rate)

    1..client_num
    |> Enum.map(fn _ ->
      # ランダムなインデックスを選ぶ
      indices = Enum.take_random(0..(len - 1), sample_size)

      # 対応する要素を取り出す
      sublist1 = Enum.map(indices, &Enum.at(local_images, &1))
      sublist2 = Enum.map(indices, &Enum.at(local_labels, &1))

      {sublist1, sublist2}  # ペアの部分リストを返す
    end)
  end

  def run(former_model_state_data \\ %{}, client_id, client_num, sample_rate) do
    epoch_num = 10

    case Process.whereis(DataLoader) do
      nil ->
        # プロセスが起動していない場合、起動する
        {:ok, _pid} = DataLoader.start_link(
          %DataLoader.DataLoaderInitArgs{
            data_name: :mnist,
            client_num: client_num,
            sample_rate: sample_rate}
          )
          IO.puts "after start DataLoader"
      _ ->
        IO.puts "already DataLoader is started"
        nil
    end

    {
      {train_images, train_labels},
      {_valid_images, _valid_labels},
      {test_images, test_labels}
    } = DataLoader.get_data(client_id)


    model =
      # Move channels to last position to match what conv layer expects
      {nil, @width, @height, @channels}
      |> build_model()
      |> IO.inspect()

    IO.write("\n\n Training Model \n\n")

    model_state =
      model
      |> train_model(train_images, train_labels, epoch_num)

    new_model_state_data = MiniD3fl.ComputeNode.AiCore.aggregate(model_state.data, former_model_state_data, 1)

    IO.write("\n\n Testing Model \n\n")

    ans = model
    |> test_model(model_state, test_images, test_labels)

    IO.write("\n\n")

    %{
      0 => %{
        "Accuracy" => accuracy
      }
    } = ans
    accuracy = Nx.to_number(accuracy)
    {:end_train, new_model_state_data, accuracy}
  end
end
