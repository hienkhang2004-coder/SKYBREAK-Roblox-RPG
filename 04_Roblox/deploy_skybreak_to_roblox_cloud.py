#!/usr/bin/env python3
"""
Wrapper entry point forwarding to 05_Pipeline_Tools_27x_9x/deploy_skybreak_to_roblox_cloud.py
"""
import runpy
from pathlib import Path

target = (
    Path(__file__).resolve().parent.parent
    / "05_Pipeline_Tools_27x_9x"
    / "deploy_skybreak_to_roblox_cloud.py"
)
runpy.run_path(str(target), run_name="__main__")
