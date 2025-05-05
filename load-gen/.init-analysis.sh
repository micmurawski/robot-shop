#!/bin/sh


python3.9 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
pip install pylint flake8 bandit mypy
