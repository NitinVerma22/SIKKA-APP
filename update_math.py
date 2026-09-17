import re

file_path = r'e:\development\SikkaPlay\lib\features\games\math_rush\screens\math_rush_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Reward logic
content = re.sub(
    r"int reward = 1;\s*if \(_selectedDifficultyMode == 'medium'\) \{\s*reward = 2;\s*\} else if \(_selectedDifficultyMode == 'hard'\) \{\s*reward = 3;\s*\} else \{\s*reward = 1;\s*\}",
    "int reward = 2;\n      if (_selectedDifficultyMode == 'medium') {\n        reward = 4;\n      } else if (_selectedDifficultyMode == 'hard') {\n        reward = 6;\n      } else {\n        reward = 2;\n      }",
    content
)

# Penalty logic
content = re.sub(
    r"int penalty = 1;\s*if \(_selectedDifficultyMode == 'medium'\) \{\s*penalty = 2;\s*\} else if \(_selectedDifficultyMode == 'hard'\) \{\s*penalty = 3;\s*\} else \{\s*penalty = 1;\s*\}",
    "int penalty = 1;\n      if (_selectedDifficultyMode == 'medium') {\n        penalty = 2;\n      } else if (_selectedDifficultyMode == 'hard') {\n        penalty = 3;\n      } else {\n        penalty = 1;\n      }",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated math_rush_screen.dart")
