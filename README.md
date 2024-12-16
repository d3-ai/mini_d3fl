# MiniD3fl[Work in Progress]

MiniD3flは、非中央集権型連合学習のシミュレーションを行うElixirベースのプロジェクトです。このプロジェクトは現在進行中です。

## 概要

MiniD3flは、以下の４つの観点を満たす非中央集権型連合学習のシミュレーターです。：

- スケーラビリティ（クライアント数）
- 通信品質の反映（帯域幅、パケットロスなど）
- クライアントの可用性
- 非同期な学習

## TODO
コード内に'#TODO'と書かれている部分を参照のこと。
- [ ] **MNISTデータの分割と、いちいちファイル読み込みせずに、VM上に配置**
- [ ] **サンプルを高度化（ノードが一列、ランダム、スター、リング）**
- [ ] **Supervised Treeの追加**

### バグ修正

- （動作検証段階であり、今後追加予定）

## インストール

このプロジェクトをローカルにインストールするには、以下の手順に従ってください：

1. **リポジトリをクローン**：

   ```bash
   git clone https://github.com/your_username/mini_d3fl.git
   cd mini_d3fl

  
2. **Elixirなどのインストール**
    - install [elixir](https://elixir-lang.org/install.html)
    - ```bash
      mix deps.get
      ```

3. **Run the Simulator Sample:**
   - ```bash
      iex --erl "+t 2000000" -S mix
     iex(1)> NumMock.measure(5)
      ```

     `+t 2000000`によって、elixir の atom数上限を2000000などにする。（Compute Nodeが1000程度の場合.）
     NumMock.measure(5)で、Compute Nodeが５個の場合の、一列のネットワークトポロジーでのサンプルが実行される。
   
