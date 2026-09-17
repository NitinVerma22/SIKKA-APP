import re

file_path = r'e:\development\SikkaPlay\lib\features\games\treasure_grid\screens\treasure_grid_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_logic = """    final positiveBlocksCount = 9 - negativeBlocksCount;
    bool hasThreeCoinTile = false;

    for (int i = 0; i < positiveBlocksCount; i++) {
      int coinReward;
      // Exactly 1 tile in positive tiles gets 3 coins; rest get 1 or 2 coins
      if (!hasThreeCoinTile && (i == positiveBlocksCount - 1 || random.nextDouble() < 0.30)) {
        coinReward = 3;
        hasThreeCoinTile = true;
      } else {
        coinReward = random.nextInt(2) + 1; // 1 or 2 coins
      }
      _grid.add(TileData(type: TileType.coin, coins: coinReward));
    }"""

new_logic = """    final positiveBlocksCount = 9 - negativeBlocksCount;
    
    // Create a pool of exact distribution requested: three 3s, four 2s, two 1s
    final pool = [3, 3, 3, 2, 2, 2, 2, 1, 1];
    pool.shuffle(random);

    for (int i = 0; i < positiveBlocksCount; i++) {
      int coinReward = pool[i];
      _grid.add(TileData(type: TileType.coin, coins: coinReward));
    }"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated treasure_grid_screen.dart")
else:
    print("Could not find the target string.")
