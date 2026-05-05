@echo off
bin\x64\NatNetFour2OSC.exe ^
  --localIP 10.21.136.107 ^
  --motiveIP 10.21.136.113 ^
  --oscSendIP 10.21.136.107 ^
  --oscSendPort 8090 ^
  --oscCtrlPort 8080 ^
  --oscMode max ^
  --frameModulo 6 ^
  --sendSkeletons ^
  --yup2zup ^
pause
