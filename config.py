import yaml
import os

from pathlib import Path
config_path = os.path.join(str(Path(__file__).parent), "config.yaml")

with open(config_path, "r") as f:
    cfg = yaml.load(f, Loader=yaml.FullLoader)