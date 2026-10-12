@echo off
rem Open the yujian fly-and-fight combat prototype locally (serves this folder over http).
cd /d "%~dp0"
start "" "http://127.0.0.1:8771/yujian_combat_proto.html"
python -m http.server 8771 --bind 127.0.0.1
