defmodule Mnist do
  @moduledoc """
  Codes from https://github.com/elixir-nx/axon/blob/main/examples/vision/mnist.exs
  """
  @batch_size 32
  @image_side_pixels 28
  @channel_value_max 255
  @label_values Enum.to_list(0..9)

  defp transform_images({bin, type, shape}) do
    bin
    |> Nx.from_binary(type)
    |> Nx.reshape({elem(shape, 0), @image_side_pixels**2})
    |> Nx.divide(@channel_value_max)
    |> Nx.to_batched(@batch_size)
    # Test split
    |> Enum.split(1750)
  end

  defp transform_labels({bin, type, _}) do
    bin
    |> Nx.from_binary(type)
    |> Nx.new_axis(-1)
    |> Nx.equal(Nx.tensor(@label_values))
    |> Nx.to_batched(@batch_size)
    # Test split
    |> Enum.split(1750)
  end

  defp build_model(input_shape) do
    Axon.input("input", shape: input_shape)
    |> Axon.dense(128, activation: :relu)
    |> Axon.dropout()
    |> Axon.dense(length(@label_values), activation: :softmax)
  end

  defp train_model(model, train_images, train_labels, epochs) do
    model
    |> Axon.Loop.trainer(:categorical_cross_entropy, Polaris.Optimizers.adamw(learning_rate: 0.005))
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(Stream.zip(train_images, train_labels), %{}, epochs: epochs, compiler: EXLA)
  end

  # defp train_model_previous(model, train_images, train_labels, epochs) do
  #   model
  #   |> Axon.Loop.trainer(:categorical_cross_entropy, :adam)
  #   |> Axon.Loop.run(Stream.zip(train_images, train_labels), %{}, compiler: EXLA, epochs: epochs)
  # end

  defp test_model(model, model_state, test_images, test_labels) do
    model
    |> Axon.Loop.evaluator()
    |> Axon.Loop.metric(:accuracy, "Accuracy")
    |> Axon.Loop.run(Stream.zip(test_images, test_labels), model_state, compiler: EXLA)
  end

  def run(former_model_state_data \\ %{}) do
    epoch_num = 1

    #TODO: 先にダウンロードしておく。あとは、データ分割をしておく。
    {images, labels} = Scidata.MNIST.download()

    {train_images, test_images} = transform_images(images)
    {train_labels, test_labels} = transform_labels(labels)

    model = build_model({nil, @image_side_pixels**2}) |> IO.inspect()

    IO.write("\n\n Training Model \n\n")

    model_state =
      model
      |> train_model(train_images, train_labels, epoch_num)

    IO.write("\n\n Testing Model \n\n")

    new_model_state_data = MiniD3fl.ComputeNode.AiCore.aggregate(model_state.data, former_model_state_data, 1)


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
